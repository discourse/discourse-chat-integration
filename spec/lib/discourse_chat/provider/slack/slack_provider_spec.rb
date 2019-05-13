# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DiscourseChat::Provider::SlackProvider do
  let(:post) { Fabricate(:post) }

  describe '.excerpt' do
    describe 'when post contains emoijs' do
      before do
        post.update!(raw: ':slight_smile: This is a test')
      end

      it 'should return the right excerpt' do
        expect(described_class.excerpt(post)).to eq('🙂 This is a test')
      end
    end

    describe 'when post contains onebox' do
      it 'should return the right excerpt' do
        post.update!(cooked: <<~COOKED
        <aside class=\"onebox whitelistedgeneric\">
          <header class=\"source\">
            <a href=\"http://somesource.com\">
              meta.discourse.org
            </a>
          </header>

          <article class=\"onebox-body\">
            <img src=\"http://somesource.com\" width=\"\" height=\"\" class=\"thumbnail\">

            <h3>
              <a href=\"http://somesource.com\">
                Some text
              </a>
            </h3>

            <p>
              some text
            </p>

          </article>

          <div class=\"onebox-metadata\">\n    \n    \n</div>
          <div style=\"clear: both\"></div>
        </aside>
        COOKED
        )

        expect(described_class.excerpt(post))
          .to eq('<http://somesource.com|meta.discourse.org>')
      end
    end

    describe 'when post contains an email' do
      it 'should return the right excerpt' do
        post.update!(cooked: <<~COOKED
            The address is <a href=\"mailto:someone@domain.com\">my email</a>
        COOKED
        )

        expect(described_class.excerpt(post))
          .to eq('The address is <mailto:someone@domain.com|my email>')
      end
    end
  end

  describe '.trigger_notifications' do
    before do
      SiteSetting.chat_integration_slack_outbound_webhook_url = "https://hooks.slack.com/services/abcde"
      SiteSetting.chat_integration_slack_enabled = true
    end

    let(:chan1) { DiscourseChat::Channel.create!(provider: 'slack', data: { identifier: '#general' }) }

    it 'sends a webhook request' do
      stub1 = stub_request(:post, SiteSetting.chat_integration_slack_outbound_webhook_url).to_return(body: "success")
      described_class.trigger_notification(post, chan1)
      expect(stub1).to have_been_requested.once
    end

    it 'handles errors correctly' do
      stub1 = stub_request(:post, SiteSetting.chat_integration_slack_outbound_webhook_url).to_return(status: 400, body: "error")
      expect(stub1).to have_been_requested.times(0)
      expect { described_class.trigger_notification(post, chan1) }.to raise_exception(::DiscourseChat::ProviderError)
      expect(stub1).to have_been_requested.once
    end

    describe 'with api token' do
      before do
        SiteSetting.chat_integration_slack_access_token = "magic"
        @stub1 = stub_request(:post, SiteSetting.chat_integration_slack_outbound_webhook_url).to_return(body: "success")
        @stub2 = stub_request(:post, %r{https://slack.com/api/chat.postMessage}).to_return(body: "{\"ok\":true, \"ts\": \"#{Time.now.to_i}.012345\", \"message\": {\"attachments\": [], \"username\":\"blah\", \"text\":\"blah2\"} }", headers: { 'Content-Type' => 'application/json' })
        @stub3 = stub_request(:post, %r{https://slack.com/api/chat.update}).to_return(body: '{"ok":true, "ts": "some_message_id"}', headers: { 'Content-Type' => 'application/json' })
      end

      it 'sends an api request' do
        expect(@stub2).to have_been_requested.times(0)

        described_class.trigger_notification(post, chan1)
        expect(@stub1).to have_been_requested.times(0)
        expect(@stub2).to have_been_requested.once
      end

      it 'handles errors correctly' do
        @stub2 = stub_request(:post, %r{https://slack.com/api/chat.postMessage}).to_return(body: "{\"ok\":false }", headers: { 'Content-Type' => 'application/json' })
        expect { described_class.trigger_notification(post, chan1) }.to raise_exception(::DiscourseChat::ProviderError)
        expect(@stub2).to have_been_requested.once
      end

    end

  end

end
