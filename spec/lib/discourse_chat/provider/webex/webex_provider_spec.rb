# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DiscourseChat::Provider::WebexProvider do
  let(:post) { Fabricate(:post) }

  describe '.trigger_notifications' do
    before do
      SiteSetting.chat_integration_webex_enabled = true
    end

    let(:chan1) { DiscourseChat::Channel.create!(provider: 'webex', data: { name: 'discourse', webhook_url: 'https://webexapis.com/v1/webhooks/incoming/jAHJjVVQ1cgEwb4ikQQawIrGdUtlocKA9fSNvIyADQoYo0mI70pztWUDOu22gDRPJOEJtCsc688zi1RMa' }) }

    it 'sends a webhook request' do
      stub1 = stub_request(:post, chan1.data['webhook_url']).to_return(body: "1")
      described_class.trigger_notification(post, chan1, nil)
      expect(stub1).to have_been_requested.once
    end

    it 'handles errors correctly' do
      stub1 = stub_request(:post, chan1.data['webhook_url']).to_return(status: 400, body: "{}")
      expect(stub1).to have_been_requested.times(0)
      expect { described_class.trigger_notification(post, chan1, nil) }.to raise_exception(::DiscourseChat::ProviderError)
      expect(stub1).to have_been_requested.once
    end

  end

end
