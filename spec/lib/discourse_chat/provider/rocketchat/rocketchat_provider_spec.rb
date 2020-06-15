# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DiscourseChat::Provider::RocketchatProvider do
  let(:post) { Fabricate(:post) }

  describe '.trigger_notifications' do
    before do
      SiteSetting.chat_integration_rocketchat_enabled = true
      SiteSetting.chat_integration_rocketchat_webhook_url = "https://example.com/abcd"
    end

    let(:chan1) { DiscourseChat::Channel.create!(provider: 'rocketchat', data: { identifier: "#general" }) }

    it 'sends a webhook request' do
      stub1 = stub_request(:post, 'https://example.com/abcd').to_return(body: "{\"success\":true}")
      described_class.trigger_notification(post, chan1, nil)
      expect(stub1).to have_been_requested.once
    end

    it 'handles errors correctly' do
      stub1 = stub_request(:post, 'https://example.com/abcd').to_return(status: 400, body: "{}")
      expect(stub1).to have_been_requested.times(0)
      expect { described_class.trigger_notification(post, chan1, nil) }.to raise_exception(::DiscourseChat::ProviderError)
      expect(stub1).to have_been_requested.once
    end

  end

end
