# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DiscourseChat::Provider::MatrixProvider do
  let(:post) { Fabricate(:post) }

  describe '.trigger_notifications' do
    before do
      SiteSetting.chat_integration_matrix_enabled = true
      SiteSetting.chat_integration_matrix_access_token = 'abcd'
    end

    let(:chan1) { DiscourseChat::Channel.create!(provider: 'matrix', data: { name: "Awesome Channel", room_id: '!blah:matrix.org' }) }

    it 'sends the message' do
      stub1 = stub_request(:put, %r{https://matrix.org/_matrix/client/r0/rooms/!blah:matrix.org/send/m.room.message/*}).to_return(status: 200)
      described_class.trigger_notification(post, chan1, nil)
      expect(stub1).to have_been_requested.once
    end

    it 'handles errors correctly' do
      stub1 = stub_request(:put, %r{https://matrix.org/_matrix/client/r0/rooms/!blah:matrix.org/send/m.room.message/*}).to_return(status: 400, body: '{"errmsg":"M_UNKNOWN"}')
      expect(stub1).to have_been_requested.times(0)
      expect { described_class.trigger_notification(post, chan1, nil) }.to raise_exception(::DiscourseChat::ProviderError)
      expect(stub1).to have_been_requested.once
    end

  end

end
