require 'rails_helper'
require_dependency 'post_creator'
require_relative '../../dummy_provider'

RSpec.describe DiscourseChat::Manager do

  let(:manager) {::DiscourseChat::Manager}  
  let(:category) {Fabricate(:category)}
  let(:topic){Fabricate(:topic, category_id: category.id )}
  let(:first_post) {Fabricate(:post, topic: topic)}
  let(:second_post) {Fabricate(:post, topic: topic, post_number:2)}

  describe '.trigger_notifications' do
    include_context "dummy provider"

    before do
      SiteSetting.chat_integration_enabled = true
    end

    def create_rule(provider, channel, filter, category_id, tags) # Just shorthand for testing purposes
      DiscourseChat::Rule.create({provider: provider, channel: channel, filter:filter, category_id:category_id, tags:tags})
    end

    it "should fail gracefully when a provider throws an exception" do
      create_rule('dummy', 'chan1', 'watch', category.id, nil)

      # Triggering a ProviderError should set the error_key to the error message
      ::DiscourseChat::Provider::DummyProvider.set_raise_exception(DiscourseChat::ProviderError.new info: {error_key:"hello"})
      manager.trigger_notifications(first_post.id)
      expect(provider.sent_messages.map{|x| x[:channel]}).to contain_exactly()
      expect(DiscourseChat::Rule.all.first.error_key).to eq('hello')

      # Triggering a different error should set the error_key to a generic message
      ::DiscourseChat::Provider::DummyProvider.set_raise_exception(StandardError.new "hello")
      manager.trigger_notifications(first_post.id)
      expect(provider.sent_messages.map{|x| x[:channel]}).to contain_exactly()
      expect(DiscourseChat::Rule.all.first.error_key).to eq('chat_integration.rule_exception')

      ::DiscourseChat::Provider::DummyProvider.set_raise_exception(nil)

      manager.trigger_notifications(first_post.id)
      expect(DiscourseChat::Rule.all.first.error_key.nil?).to be true      
    end

    it "should not send notifications when provider is disabled" do
      SiteSetting.chat_integration_enabled = false
      create_rule('dummy', 'chan1', 'watch', category.id, nil)

      manager.trigger_notifications(first_post.id)

      expect(provider.sent_messages.map{|x| x[:channel]}).to contain_exactly()
    end

    it "should send a notification to watched and following channels for new topic" do

      create_rule('dummy', 'chan1', 'watch', category.id, nil)
      create_rule('dummy', 'chan2', 'follow', category.id, nil)
      create_rule('dummy', 'chan3', 'mute', category.id, nil)

      manager.trigger_notifications(first_post.id)

      expect(provider.sent_messages.map{|x| x[:channel]}).to contain_exactly('chan1', 'chan2')
    end

    it "should send a notification only to watched for reply" do
      create_rule('dummy', 'chan1', 'watch', category.id, nil)
      create_rule('dummy', 'chan2', 'follow', category.id, nil)
      create_rule('dummy', 'chan3', 'mute', category.id, nil)

      manager.trigger_notifications(second_post.id)

      expect(provider.sent_messages.map{|x| x[:channel]}).to contain_exactly('chan1')
    end

    it "should respect wildcard category settings" do
      create_rule('dummy', 'chan1', 'watch', nil, nil)

      manager.trigger_notifications(first_post.id)

      expect(provider.sent_messages.map{|x| x[:channel]}).to contain_exactly('chan1')
    end

    it "should respect mute over watch" do
      create_rule('dummy', 'chan1', 'watch', nil, nil) # Wildcard watch
      create_rule('dummy', 'chan1', 'mute', category.id, nil) # Specific mute

      manager.trigger_notifications(first_post.id)

      expect(provider.sent_messages.map{|x| x[:channel]}).to contain_exactly()
    end

    it "should respect watch over follow" do
      create_rule('dummy', 'chan1', 'follow', nil, nil)
      create_rule('dummy', 'chan1', 'watch', category.id, nil)

      manager.trigger_notifications(second_post.id)

      expect(provider.sent_messages.map{|x| x[:channel]}).to contain_exactly('chan1')
    end

    it "should not notify about private messages" do
      create_rule('dummy', 'chan1', 'watch', nil, nil)
      private_post = Fabricate(:private_message_post)

      manager.trigger_notifications(private_post.id)

      expect(provider.sent_messages.map{|x| x[:channel]}).to contain_exactly()
    end

    it "should not notify about private messages" do
      create_rule('dummy', 'chan1', 'watch', nil, nil)
      private_post = Fabricate(:private_message_post)

      manager.trigger_notifications(private_post.id)

      expect(provider.sent_messages.map{|x| x[:channel]}).to contain_exactly()
    end

    it "should not notify about posts the chat_user cannot see" do
      create_rule('dummy', 'chan1', 'watch', nil, nil)

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
      expect(provider.sent_messages.map{|x| x[:channel]}).to contain_exactly()

      # Now expose category to new user
      category.set_permissions(Group[:friends] => :full)
      category.save!

      # Check notification sent
      manager.trigger_notifications(first_post.id)
      expect(provider.sent_messages.map{|x| x[:channel]}).to contain_exactly('chan1')

    end

    describe 'with tags enabled' do
      let(:tag){Fabricate(:tag, name:'gsoc')}
      let(:tagged_topic){Fabricate(:topic, category_id: category.id, tags: [tag])}
      let(:tagged_first_post) {Fabricate(:post, topic: tagged_topic)}

      before(:each) do
        SiteSetting.tagging_enabled = true
      end

      it 'should still work for rules without any tags specified' do
        create_rule('dummy', 'chan1', 'watch', category.id, nil)

        manager.trigger_notifications(first_post.id)
        manager.trigger_notifications(tagged_first_post.id)

        expect(provider.sent_messages.map{|x| x[:channel]}).to contain_exactly('chan1','chan1')
      end

      it 'should only match tagged topics when rule has tags' do
        create_rule('dummy', 'chan1', 'watch', category.id, [tag.name])

        manager.trigger_notifications(first_post.id)
        manager.trigger_notifications(tagged_first_post.id)

        expect(provider.sent_messages.map{|x| x[:channel]}).to contain_exactly('chan1')
      end

    end
  end

end