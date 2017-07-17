
RSpec.shared_context "dummy provider" do
  before(:each) do
    if defined? ::DiscourseChat::Provider::DummyProvider
      ::DiscourseChat::Provider.send(:remove_const, :DummyProvider)
    end
    
    module ::DiscourseChat::Provider::DummyProvider
      PROVIDER_NAME = "dummy".freeze
      PROVIDER_ENABLED_SETTING = :chat_integration_enabled # Tie to main plugin enabled setting
      @@sent_messages = []
      @@raise_exception = nil

      def self.trigger_notification(post, channel)
        if @@raise_exception
          raise @@raise_exception
        end
        @@sent_messages.push(post: post.id, channel: channel)
      end

      def self.sent_messages
        @@sent_messages
      end

      def self.set_raise_exception(bool)
        @@raise_exception = bool
      end
    end
    
  end

  let(:provider){::DiscourseChat::Provider::DummyProvider}
  
end

RSpec.configure do |rspec|
  rspec.include_context "dummy provider"
end