require 'rails_helper'

RSpec.describe DiscourseChat::Provider::HipchatProvider do
  let(:post) { Fabricate(:post) }

  describe '.trigger_notifications' do
    before do
      SiteSetting.chat_integration_hipchat_enabled = true
    end

    let(:chan1){DiscourseChat::Channel.create!(provider:'hipchat', data:{name: "Awesome Channel", webhook_url: 'https://blah.hipchat.com/abcd', color: "red"})}

    it 'sends a webhook request' do
      stub1 = stub_request(:post, 'https://blah.hipchat.com/abcd').to_return(status: 200)
      described_class.trigger_notification(post, chan1)
      expect(stub1).to have_been_requested.once
    end

    it 'handles errors correctly' do 
      stub1 = stub_request(:post, "https://blah.hipchat.com/abcd").to_return(status: 400)
      expect(stub1).to have_been_requested.times(0)
      expect{described_class.trigger_notification(post, chan1)}.to raise_exception(::DiscourseChat::ProviderError)
      expect(stub1).to have_been_requested.once
    end

  end

end
