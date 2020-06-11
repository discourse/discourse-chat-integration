# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DiscourseChat::Provider::GitterProvider do
  let(:post) { Fabricate(:post) }

  describe '.trigger_notifications' do
    before do
      SiteSetting.chat_integration_gitter_enabled = true
    end

    let(:chan1) { DiscourseChat::Channel.create!(provider: 'gitter', data: { name: 'gitterHQ/services', webhook_url: 'https://webhooks.gitter.im/e/a1e2i3o4u5' }) }

    it 'sends a webhook request' do
      stub1 = stub_request(:post, chan1.data['webhook_url']).to_return(body: "OK")
      described_class.trigger_notification(post, chan1, nil)
      expect(stub1).to have_been_requested.once
    end

    it 'handles errors correctly' do
      stub1 = stub_request(:post, chan1.data['webhook_url']).to_return(status: 404, body: "{ \"error\": \"Not Found\"}")
      expect(stub1).to have_been_requested.times(0)
      expect { described_class.trigger_notification(post, chan1, nil) }.to raise_exception(::DiscourseChat::ProviderError)
      expect(stub1).to have_been_requested.once
    end
  end
end
