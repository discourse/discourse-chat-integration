# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DiscourseChat::Provider::ZulipProvider do
  let(:post) { Fabricate(:post) }

  describe '.trigger_notifications' do
    before do
      SiteSetting.chat_integration_zulip_enabled = true
      SiteSetting.chat_integration_zulip_server = "https://hello.world"
      SiteSetting.chat_integration_zulip_bot_email_address = "some_bot@example.com"
      SiteSetting.chat_integration_zulip_bot_api_key = "secret"
    end

    let(:chan1) { DiscourseChat::Channel.create!(provider: 'zulip', data: { stream: "general", subject: "Discourse Notifications" }) }

    it 'sends a webhook request' do
      stub1 = stub_request(:post, 'https://hello.world/api/v1/messages').to_return(status: 200)
      described_class.trigger_notification(post, chan1, nil)
      expect(stub1).to have_been_requested.once
    end

    it 'handles errors correctly' do
      stub1 = stub_request(:post, 'https://hello.world/api/v1/messages').to_return(status: 400, body: '{}')
      expect(stub1).to have_been_requested.times(0)
      expect { described_class.trigger_notification(post, chan1, nil) }.to raise_exception(::DiscourseChat::ProviderError)
      expect(stub1).to have_been_requested.once
    end

  end

end
