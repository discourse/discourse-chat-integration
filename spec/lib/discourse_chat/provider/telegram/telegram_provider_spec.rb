# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DiscourseChat::Provider::TelegramProvider do
  let(:post) { Fabricate(:post) }

  describe '.trigger_notifications' do
    before do
      SiteSetting.chat_integration_telegram_access_token = "TOKEN"
      SiteSetting.chat_integration_telegram_secret = 'shhh'
      SiteSetting.chat_integration_telegram_enabled = true
    end

    let(:chan1) { DiscourseChat::Channel.create!(provider: 'telegram', data: { name: "Awesome Channel", chat_id: '123' }) }

    it 'sends a webhook request' do
      stub1 = stub_request(:post, 'https://api.telegram.org/botTOKEN/sendMessage').to_return(body: "{\"ok\":true}")
      described_class.trigger_notification(post, chan1, nil)
      expect(stub1).to have_been_requested.once
    end

    it 'handles errors correctly' do
      stub1 = stub_request(:post, 'https://api.telegram.org/botTOKEN/sendMessage').to_return(body: "{\"ok\":false, \"description\":\"chat not found\"}")
      expect(stub1).to have_been_requested.times(0)
      expect { described_class.trigger_notification(post, chan1, nil) }.to raise_exception(::DiscourseChat::ProviderError)
      expect(stub1).to have_been_requested.once
    end

  end

end
