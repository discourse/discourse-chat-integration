# frozen_string_literal: true

require 'rails_helper'
require_dependency 'post_creator'
require_relative '../dummy_provider'

RSpec.describe DiscourseChat::Manager do

  let(:manager) { ::DiscourseChat::Manager }
  let(:category) { Fabricate(:category) }
  let(:group) { Fabricate(:group) }
  let(:group2) { Fabricate(:group) }
  let(:topic) { Fabricate(:topic, category_id: category.id) }
  let(:first_post) { Fabricate(:post, topic: topic) }
  let(:second_post) { Fabricate(:post, topic: topic, post_number: 2) }

  describe '.trigger_notifications' do
    include_context "dummy provider"

    let(:chan1) { DiscourseChat::Channel.create!(provider: 'dummy') }
    let(:chan2) { DiscourseChat::Channel.create!(provider: 'dummy') }
    let(:chan3) { DiscourseChat::Channel.create!(provider: 'dummy') }

    before do
      SiteSetting.chat_integration_enabled = true
    end

    it "should fail gracefully when a provider throws an exception" do
      DiscourseChat::Rule.create!(channel: chan1, filter: 'watch', category_id: category.id)

      # Triggering a ProviderError should set the error_key to the error message
      provider.set_raise_exception(DiscourseChat::ProviderError.new info: { error_key: "hello" })
      manager.trigger_notifications(first_post.id)
      expect(provider.sent_to_channel_ids).to contain_exactly()
      expect(DiscourseChat::Channel.all.first.error_key).to eq('hello')

      # Triggering a different error should set the error_key to a generic message
      provider.set_raise_exception(StandardError.new "hello")
      manager.trigger_notifications(first_post.id)
      expect(provider.sent_to_channel_ids).to contain_exactly()
      expect(DiscourseChat::Channel.all.first.error_key).to eq('chat_integration.channel_exception')

      provider.set_raise_exception(nil)

      manager.trigger_notifications(first_post.id)
      expect(DiscourseChat::Channel.all.first.error_key.nil?).to be true
    end

    it "should not send notifications when provider is disabled" do
      SiteSetting.chat_integration_enabled = false
      DiscourseChat::Rule.create!(channel: chan1, filter: 'watch', category_id: category.id)

      manager.trigger_notifications(first_post.id)

      expect(provider.sent_to_channel_ids).to contain_exactly()
    end

    it "should send a notification to watched and following channels for new topic" do
      DiscourseChat::Rule.create!(channel: chan1, filter: 'watch', category_id: category.id)
      DiscourseChat::Rule.create!(channel: chan2, filter: 'follow', category_id: category.id)
      DiscourseChat::Rule.create!(channel: chan3, filter: 'mute', category_id: category.id)

      manager.trigger_notifications(first_post.id)

      expect(provider.sent_to_channel_ids).to contain_exactly(chan1.id, chan2.id)
    end

    it "should send a notification only to watched for reply" do
      DiscourseChat::Rule.create!(channel: chan1, filter: 'watch', category_id: category.id)
      DiscourseChat::Rule.create!(channel: chan2, filter: 'follow', category_id: category.id)
      DiscourseChat::Rule.create!(channel: chan3, filter: 'mute', category_id: category.id)

      manager.trigger_notifications(second_post.id)

      expect(provider.sent_to_channel_ids).to contain_exactly(chan1.id)
    end

    it "should respect wildcard category settings" do
      DiscourseChat::Rule.create!(channel: chan1, filter: 'watch', category_id: nil)

      manager.trigger_notifications(first_post.id)

      expect(provider.sent_to_channel_ids).to contain_exactly(chan1.id)
    end

    it "should respect mute over watch" do
      DiscourseChat::Rule.create!(channel: chan1, filter: 'watch', category_id: nil) # Wildcard watch
      DiscourseChat::Rule.create!(channel: chan1, filter: 'mute', category_id: category.id) # Specific mute

      manager.trigger_notifications(first_post.id)

      expect(provider.sent_to_channel_ids).to contain_exactly()
    end

    it "should respect watch over follow" do
      DiscourseChat::Rule.create!(channel: chan1, filter: 'follow', category_id: nil) # Wildcard follow
      DiscourseChat::Rule.create!(channel: chan1, filter: 'watch', category_id: category.id) # Specific watch

      manager.trigger_notifications(second_post.id)

      expect(provider.sent_to_channel_ids).to contain_exactly(chan1.id)
    end

    it "should respect thread over watch" do
      DiscourseChat::Rule.create!(channel: chan1, filter: 'watch', category_id: nil) # Wildcard watch
      DiscourseChat::Rule.create!(channel: chan1, filter: 'thread', category_id: category.id) # Specific thread

      manager.trigger_notifications(second_post.id)

      expect(provider.sent_to_channel_ids).to contain_exactly(chan1.id)
    end

    it "should not notify about private messages" do
      DiscourseChat::Rule.create!(channel: chan1, filter: 'follow', category_id: nil) # Wildcard watch

      private_post = Fabricate(:private_message_post)

      manager.trigger_notifications(private_post.id)

      expect(provider.sent_to_channel_ids).to contain_exactly()
    end

    it "should work for group pms" do
      DiscourseChat::Rule.create!(channel: chan1, filter: 'watch') # Wildcard watch
      DiscourseChat::Rule.create!(channel: chan2, type: 'group_message', filter: 'watch', group_id: group.id) # Group watch

      private_post = Fabricate(:private_message_post)
      private_post.topic.invite_group(Fabricate(:user), group)

      manager.trigger_notifications(private_post.id)

      expect(provider.sent_to_channel_ids).to contain_exactly(chan2.id)
    end

    it "should work for pms with multiple groups" do
      DiscourseChat::Rule.create!(channel: chan1, type: 'group_message', filter: 'watch', group_id: group.id)
      DiscourseChat::Rule.create!(channel: chan2, type: 'group_message', filter: 'watch', group_id: group2.id)

      private_post = Fabricate(:private_message_post)
      private_post.topic.invite_group(Fabricate(:user), group)
      private_post.topic.invite_group(Fabricate(:user), group2)

      manager.trigger_notifications(private_post.id)

      expect(provider.sent_to_channel_ids).to contain_exactly(chan1.id, chan2.id)
    end

    it "should work for group mentions" do
      third_post = Fabricate(:post, topic: topic, post_number: 3, raw: "let's mention @#{group.name}")

      DiscourseChat::Rule.create!(channel: chan1, filter: 'watch') # Wildcard watch
      DiscourseChat::Rule.create!(channel: chan2, type: 'group_message', filter: 'watch', group_id: group.id)
      DiscourseChat::Rule.create!(channel: chan3, type: 'group_mention', filter: 'watch', group_id: group.id)

      manager.trigger_notifications(third_post.id)
      expect(provider.sent_to_channel_ids).to contain_exactly(chan1.id, chan3.id)
    end

    it "should give group rule precedence over normal rules" do
      third_post = Fabricate(:post, topic: topic, post_number: 3, raw: "let's mention @#{group.name}")

      DiscourseChat::Rule.create!(channel: chan1, filter: 'mute', category_id: category.id) # Mute category
      manager.trigger_notifications(third_post.id)
      expect(provider.sent_to_channel_ids).to contain_exactly()

      DiscourseChat::Rule.create!(channel: chan1, filter: 'watch', type: 'group_mention', group_id: group.id) # Watch mentions
      manager.trigger_notifications(third_post.id)
      expect(provider.sent_to_channel_ids).to contain_exactly(chan1.id)
    end

    it "should not notify about mentions in private messages" do
      # Group 1 watching for messages on channel 1
      DiscourseChat::Rule.create!(channel: chan1, filter: 'watch', type: 'group_message', group_id: group.id)
      # Group 2 watching for mentions on channel 2
      DiscourseChat::Rule.create!(channel: chan2, filter: 'watch', type: 'group_mention', group_id: group2.id)

      # Make a private message only accessible to group 1
      private_message = Fabricate(:private_message_post)
      private_message.topic.invite_group(Fabricate(:user), group)

      # Mention group 2 in the message
      mention_post = Fabricate(:post, topic: private_message.topic, post_number: 2, raw: "let's mention @#{group2.name}")

      # We expect that only group 1 receives a notification
      manager.trigger_notifications(mention_post.id)
      expect(provider.sent_to_channel_ids).to contain_exactly(chan1.id)
    end

    it "should not notify about posts the chat_user cannot see" do
      DiscourseChat::Rule.create!(channel: chan1, filter: 'follow', category_id: nil) # Wildcard watch

      # Create a group & user
      group = Fabricate(:group, name: "friends")
      user = Fabricate(:user, username: 'david')
      group.add(user)

      # Set the chat_user to the newly created non-admin user
      SiteSetting.chat_integration_discourse_username = 'david'

      # Create a category
      category = Fabricate(:category, name: "Test category")
      topic.category = category
      topic.save!

      # Restrict category to admins only
      category.set_permissions(Group[:admins] => :full)
      category.save!

      # Check no notification sent
      manager.trigger_notifications(first_post.id)
      expect(provider.sent_to_channel_ids).to contain_exactly()

      # Now expose category to new user
      category.set_permissions(Group[:friends] => :full)
      category.save!

      # Check notification sent
      manager.trigger_notifications(first_post.id)
      expect(provider.sent_to_channel_ids).to contain_exactly(chan1.id)

    end

    describe 'with tags enabled' do
      let(:tag) { Fabricate(:tag, name: 'gsoc') }
      let(:tagged_topic) { Fabricate(:topic, category_id: category.id, tags: [tag]) }
      let(:tagged_first_post) { Fabricate(:post, topic: tagged_topic) }

      before(:each) do
        SiteSetting.tagging_enabled = true
      end

      it 'should still work for rules without any tags specified' do
        DiscourseChat::Rule.create!(channel: chan1, filter: 'follow', category_id: nil) # Wildcard watch

        manager.trigger_notifications(first_post.id)
        manager.trigger_notifications(tagged_first_post.id)

        expect(provider.sent_to_channel_ids).to contain_exactly(chan1.id, chan1.id)
      end

      it 'should only match tagged topics when rule has tags' do
        DiscourseChat::Rule.create!(channel: chan1, filter: 'follow', category_id: category.id, tags: [tag.name])

        manager.trigger_notifications(first_post.id)
        manager.trigger_notifications(tagged_first_post.id)

        expect(provider.sent_to_channel_ids).to contain_exactly(chan1.id)
      end

    end
  end

end
