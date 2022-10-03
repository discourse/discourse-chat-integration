# frozen_string_literal: true

RSpec.shared_context "with dummy provider" do
  before(:each) do
    module ::DiscourseChatIntegration::Provider::DummyProvider
      PROVIDER_NAME = "dummy".freeze
      PROVIDER_ENABLED_SETTING = :chat_integration_enabled # Tie to main plugin enabled setting
      CHANNEL_PARAMETERS = []

      @@sent_messages = []
      @@raise_exception = nil

      def self.trigger_notification(post, channel, rule)
        if @@raise_exception
          raise @@raise_exception
        end

        @@sent_messages.push(post: post.id, channel: channel)
      end

      def self.sent_messages
        @@sent_messages
      end

      def self.sent_to_channel_ids
        @@sent_messages.map { |x| x[:channel].id }
      end

      def self.set_raise_exception(bool)
        @@raise_exception = bool
      end
    end
  end

  after(:each) do
    ::DiscourseChatIntegration::Provider.send(:remove_const, :DummyProvider)
  end

  let(:provider) { ::DiscourseChatIntegration::Provider::DummyProvider }
end

RSpec.shared_context "with validated dummy provider" do
  before(:each) do
    module ::DiscourseChatIntegration::Provider::Dummy2Provider
      PROVIDER_NAME = "dummy2".freeze
      PROVIDER_ENABLED_SETTING = :chat_integration_enabled # Tie to main plugin enabled setting
      CHANNEL_PARAMETERS = [
                            { key: "val", regex: '^\S+$', unique: true }
                           ]

      @@sent_messages = []

      def self.trigger_notification(post, channel, rule)
        @@sent_messages.push(post: post.id, channel: channel)
      end

      def self.sent_messages
        @@sent_messages
      end
    end

  end

  after(:each) do
    ::DiscourseChatIntegration::Provider.send(:remove_const, :Dummy2Provider)
  end
end
