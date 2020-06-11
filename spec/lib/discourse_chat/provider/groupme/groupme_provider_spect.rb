# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DiscourseChat::Provider::GroupmeProvider do
  let(:post) { Fabricate(:post) }

  describe '.trigger_notifications' do
    before do
      SiteSetting.chat_integration_groupme_enabled = true
      SiteSetting.chat_integration_groupme_bot_ids = '1a2b3c4d5e6f7g'
    end

    let(:chan1) { DiscourseChat::Channel.create!(provider: 'groupme', data: { groupme_bot_id: '1a2b3c4d5e6f7g' }) }

    it 'sends a request' do
      stub1 = stub_request(:post, "https://api.groupme.com/v3/bots/post").to_return(status: 200)
      described_class.trigger_notification(post, chan1, nil)
      expect(stub1).to have_been_requested.once
    end

    it 'handles errors correctly' do
      stub1 = stub_request(:post, "https://api.groupme.com/v3/bots/post").to_return(status: 404, body: "{ \"error\": \"Not Found\"}")
      expect(stub1).to have_been_requested.times(0)
      expect { described_class.trigger_notification(post, chan1, nil) }.to raise_exception(::DiscourseChat::ProviderError)
      expect(stub1).to have_been_requested.once
    end
  end
end
