require 'rails_helper'
require_dependency 'post_creator'

RSpec.describe DiscourseChat::Manager do

  let(:manager) {::DiscourseChat::Manager}  
  let(:category) {Fabricate(:category)}
  let(:topic){Fabricate(:topic, category_id: category.id )}
  let(:first_post) {Fabricate(:post, topic: topic)}
  let(:second_post) {Fabricate(:post, topic: topic, post_number:2)}

  describe '.trigger_notifications' do
    before(:each) do 
      module ::DiscourseChat::Provider::DummyProvider
        PROVIDER_NAME = "dummy".freeze
        @@sent_messages = []

        def self.trigger_notification(post, channel)
          @@sent_messages.push(post: post.id, channel: channel)
        end

        def self.sent_messages
          @@sent_messages
        end
      end
    end

    after(:each) do
      ::DiscourseChat::Provider.send(:remove_const, :DummyProvider)
    end

    let(:provider) {::DiscourseChat::Provider::DummyProvider}

    it "should send a notification to watched and following channels for new topic" do
      manager.create_rule('dummy', 'chan1', 'watch', category.id, nil)
      manager.create_rule('dummy', 'chan2', 'follow', category.id, nil)
      manager.create_rule('dummy', 'chan3', 'mute', category.id, nil)

      manager.trigger_notifications(first_post.id)

      expect(provider.sent_messages.map{|x| x[:channel]}).to contain_exactly('chan1', 'chan2')
    end

    it "should send a notification only to watched for reply" do
      manager.create_rule('dummy', 'chan1', 'watch', category.id, nil)
      manager.create_rule('dummy', 'chan2', 'follow', category.id, nil)
      manager.create_rule('dummy', 'chan3', 'mute', category.id, nil)

      manager.trigger_notifications(second_post.id)

      expect(provider.sent_messages.map{|x| x[:channel]}).to contain_exactly('chan1')
    end

    it "should respect wildcard category settings" do
      manager.create_rule('dummy', 'chan1', 'watch', nil, nil)

      manager.trigger_notifications(first_post.id)

      expect(provider.sent_messages.map{|x| x[:channel]}).to contain_exactly('chan1')
    end

    it "should respect mute over watch" do
      manager.create_rule('dummy', 'chan1', 'watch', nil, nil) # Wildcard watch
      manager.create_rule('dummy', 'chan1', 'mute', category.id, nil) # Specific mute

      manager.trigger_notifications(first_post.id)

      expect(provider.sent_messages.map{|x| x[:channel]}).to contain_exactly()
    end

    it "should respect watch over follow" do
      manager.create_rule('dummy', 'chan1', 'follow', nil, nil)
      manager.create_rule('dummy', 'chan1', 'watch', category.id, nil)

      manager.trigger_notifications(second_post.id)

      expect(provider.sent_messages.map{|x| x[:channel]}).to contain_exactly('chan1')
    end

    it "should not notify about private messages" do
      manager.create_rule('dummy', 'chan1', 'watch', nil, nil)
      private_post = Fabricate(:private_message_post)

      manager.trigger_notifications(private_post.id)

      expect(provider.sent_messages.map{|x| x[:channel]}).to contain_exactly()
    end

    it "should not notify about private messages" do
      manager.create_rule('dummy', 'chan1', 'watch', nil, nil)
      private_post = Fabricate(:private_message_post)

      manager.trigger_notifications(private_post.id)

      expect(provider.sent_messages.map{|x| x[:channel]}).to contain_exactly()
    end

    it "should not notify about posts the chat_user cannot see" do
      manager.create_rule('dummy', 'chan1', 'watch', nil, nil)

      # Create a group & user
      group = Fabricate(:group, name: "friends")
      user = Fabricate(:user, username: 'david')
      group.add(user)

      # Set the chat_user to the newly created non-admin user
      SiteSetting.chat_discourse_username = 'david'

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
        manager.create_rule('dummy', 'chan1', 'watch', category.id, nil)

        manager.trigger_notifications(first_post.id)
        manager.trigger_notifications(tagged_first_post.id)

        expect(provider.sent_messages.map{|x| x[:channel]}).to contain_exactly('chan1','chan1')
      end

      it 'should only match tagged topics when rule has tags' do
        manager.create_rule('dummy', 'chan1', 'watch', category.id, [tag.name])

        manager.trigger_notifications(first_post.id)
        manager.trigger_notifications(tagged_first_post.id)

        expect(provider.sent_messages.map{|x| x[:channel]}).to contain_exactly('chan1')
      end

    end
  end


  describe '.create_rule' do
    it 'should add new rule correctly' do
      expect do
        manager.create_rule('dummy', 'chan1', 'watch', category.id, nil)
      end.to change { manager.get_rules_for_category(category.id).length }.by(1)

      expect do
        manager.create_rule('dummy', 'chan2', 'follow', category.id, nil)
      end.to change { manager.get_rules_for_category(category.id).length }.by(1)
    end

    it 'should accept tags correctly' do
      tag = Fabricate(:tag)
      expect do
        manager.create_rule('dummy', 'chan1', 'watch', category.id, [tag.name, 'faketag'])
      end.to change { manager.get_rules_for_category(category.id).length }.by(1)

      expect(manager.get_rules_for_category(category.id).first[:tags]).to contain_exactly(tag.name)

    end

    it 'should error on invalid filter strings' do
      expect do
        manager.create_rule('dummy', 'chan1', 'invalid_filter', category.id, nil)
      end.to raise_error(RuntimeError, "Invalid filter")
    end


  end


end