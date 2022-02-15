# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DiscourseChatIntegration::Provider::DiscordProvider do
  let(:post) { Fabricate(:post) }

  describe '.trigger_notifications' do
    before do
      SiteSetting.chat_integration_discord_enabled = true
    end

    let(:chan1) { DiscourseChatIntegration::Channel.create!(provider: 'discord', data: { name: "Awesome Channel", webhook_url: 'https://discord.com/api/webhooks/1234/abcd' }) }

    it 'sends a webhook request' do
      stub1 = stub_request(:post, 'https://discord.com/api/webhooks/1234/abcd?wait=true').to_return(status: 200)
      described_class.trigger_notification(post, chan1, nil)
      expect(stub1).to have_been_requested.once
    end

    it 'includes the protocol in the avatar URL' do
      stub1 = stub_request(:post, 'https://discord.com/api/webhooks/1234/abcd?wait=true')
        .with(body: hash_including(embeds: [hash_including(author: hash_including(url: /^https?:\/\//))]))
        .to_return(status: 200)
      described_class.trigger_notification(post, chan1, nil)
      expect(stub1).to have_been_requested.once
    end

    it 'handles errors correctly' do
      stub1 = stub_request(:post, "https://discord.com/api/webhooks/1234/abcd?wait=true").to_return(status: 400)
      expect(stub1).to have_been_requested.times(0)
      expect { described_class.trigger_notification(post, chan1, nil) }.to raise_exception(::DiscourseChatIntegration::ProviderError)
      expect(stub1).to have_been_requested.once
    end

  end

end
