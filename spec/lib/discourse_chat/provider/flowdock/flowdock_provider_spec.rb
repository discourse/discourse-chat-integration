# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DiscourseChat::Provider::FlowdockProvider do
  let(:post) { Fabricate(:post) }

  describe '.trigger_notifications' do
    before do
      SiteSetting.chat_integration_flowdock_enabled = true
    end

    let(:chan1) { DiscourseChat::Channel.create!(provider: 'flowdock', data: { flow_token: '5d1fe04cf66e078d6a2b579ddb8a465b' }) }

    it 'sends a request' do
      stub1 = stub_request(:post, "https://api.flowdock.com/messages").to_return(status: 200)
      described_class.trigger_notification(post, chan1, nil)
      expect(stub1).to have_been_requested.once
    end

    it 'handles errors correctly' do
      stub1 = stub_request(:post, "https://api.flowdock.com/messages").to_return(status: 404, body: "{ \"error\": \"Not Found\"}")
      expect(stub1).to have_been_requested.times(0)
      expect { described_class.trigger_notification(post, chan1, nil) }.to raise_exception(::DiscourseChat::ProviderError)
      expect(stub1).to have_been_requested.once
    end
  end
end
