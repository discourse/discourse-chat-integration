require 'rails_helper'

describe 'Public Controller', type: :request do
  
  before do
    SiteSetting.chat_integration_enabled = true
  end

  describe 'loading a transcript' do
    
    it 'should be able to load a transcript' do
      key = DiscourseChat::Helper.save_transcript("Some content here")

      get "/chat-transcript/#{key}.json"

      expect(response).to be_success

      expect(response.body).to eq('{"content":"Some content here"}')
    end

    it 'should 404 for non-existant transcript' do
      key = 'abcdefghijk'
      get "/chat-transcript/#{key}.json"

      expect(response).not_to be_success
    end
    
  end

end
