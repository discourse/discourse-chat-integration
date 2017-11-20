require 'rails_helper'

RSpec.describe DiscourseChat::Provider::MattermostProvider do
  let(:post) { Fabricate(:post) }

  describe '.trigger_notifications' do
    before do
      SiteSetting.chat_integration_mattermost_enabled = true
      SiteSetting.chat_integration_mattermost_webhook_url = "https://mattermost.blah/hook/abcd"
    end

    let(:chan1) { DiscourseChat::Channel.create!(provider: 'mattermost', data: { identifier: "#awesomechannel" }) }

    it 'sends a webhook request' do
      stub1 = stub_request(:post, 'https://mattermost.blah/hook/abcd').to_return(status: 200)
      described_class.trigger_notification(post, chan1)
      expect(stub1).to have_been_requested.once
    end

    it 'uses correct logo' do
      # Defaults to small logo url
      SiteSetting.logo_small_url = "https://some_small_logo"
      message = described_class.mattermost_message(post, chan1)
      expect(message[:icon_url]).to eq(SiteSetting.logo_small_url)

      # If specific logo provided, use that
      SiteSetting.chat_integration_mattermost_icon_url = "https://specific_logo"
      message = described_class.mattermost_message(post, chan1)
      expect(message[:icon_url]).to eq(SiteSetting.chat_integration_mattermost_icon_url)
    end

    it 'handles errors correctly' do
      stub1 = stub_request(:post, "https://mattermost.blah/hook/abcd").to_return(status: 500, body: "error")
      expect(stub1).to have_been_requested.times(0)
      expect { described_class.trigger_notification(post, chan1) }.to raise_exception(::DiscourseChat::ProviderError)
      expect(stub1).to have_been_requested.once
    end

  end

end
