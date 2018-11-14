require 'rails_helper'

RSpec.describe DiscourseChat::Provider::SlackProvider::SlackTranscript do

  let(:messages_fixture) {
    [
      {
        "type": "message",
        "user": "U6JSSESES",
        "text": "Yeah, should make posting slack transcripts much easier",
        "ts": "1501801665.062694"
      },
      {
          "type": "message",
          "user": "U5Z773QLS",
          "text": "Oooh a new discourse plugin???",
          "ts": "1501801643.056375"
      },
      {
          "type": "message",
          "user": "U6E2W7R8C",
          "text": "Which one?",
          "ts": "1501801634.053761"
      },
      {
          "type": "message",
          "user": "U6JSSESES",
          "text": "So, who's interested in the new <https://meta.discourse.org|discourse plugin>?",
          "ts": "1501801629.052212"
      },
      {
          "type": "message",
          "user": "U6E2W7R8C",
          "text": "I'm interested!!",
          "ts": "1501801634.053761",
          "thread_ts": "1501801629.052212"
      },
      {
            "text": "",
            "username": "Test Community",
            "bot_id": "B6C6JNUDN",
            "attachments": [
                {
                    "author_name": "@david",
                    "fallback": "Discourse can now be integrated with Mattermost! - @david",
                    "text": "Hey <http://localhost/groups/team|@team>, what do you think about this?",
                    "title": "Discourse can now be integrated with Mattermost! [Announcements] ",
                    "id": 1,
                    "title_link": "http://localhost:3000/t/discourse-can-now-be-integrated-with-mattermost/51/4",
                    "color": "283890",
                    "mrkdwn_in": [
                        "text"
                    ]
                }
            ],
            "type": "message",
            "subtype": "bot_message",
            "ts": "1501615820.949638"
        },
        {
            "type": "message",
            "user": "U5Z773QLS",
            "text": "Let’s try some *bold text*",
            "ts": "1501093331.439776"
        },

    ]
  }

  let(:transcript) { described_class.new(channel_name: "#general", channel_id: "G1234") }
  before do
    SiteSetting.chat_integration_slack_access_token = "abcde"
  end

  describe 'loading users' do
    it 'loads users correctly' do
      stub_request(:post, "https://slack.com/api/users.list")
        .with(body: { token: "abcde", "cursor": nil, "limit": "200" })
        .to_return(status: 200, body: { ok: true, members: [{ id: "U5Z773QLS", name: "awesomeguy", profile: { image_24: "https://example.com/avatar" } }], response_metadata: { next_cursor: "" } }.to_json)

      expect(transcript.load_user_data).to be_truthy
    end

    it 'handles failed connection' do
      stub_request(:post, "https://slack.com/api/users.list")
        .to_return(status: 500, body: '')

      expect(transcript.load_user_data).to be_falsey
    end

    it 'handles slack failure' do
      stub_request(:post, "https://slack.com/api/users.list")
        .to_return(status: 200, body: { ok: false }.to_json)

      expect(transcript.load_user_data).to be_falsey
    end
  end

  context 'with loaded users' do
    before do
      stub_request(:post, "https://slack.com/api/users.list")
        .to_return(status: 200, body: { ok: true, members: [{ id: "U5Z773QLS", name: "awesomeguy", profile: { image_24: "https://example.com/avatar" } }], response_metadata: { next_cursor: "" } }.to_json)
      transcript.load_user_data
    end

    describe 'loading history' do
      it 'loads messages correctly' do
        stub_request(:post, "https://slack.com/api/conversations.history")
          .with(body: hash_including(token: "abcde", channel: 'G1234'))
          .to_return(status: 200, body: { ok: true, messages: messages_fixture }.to_json)

          expect(transcript.load_chat_history).to be_truthy
      end

      it 'handles failed connection' do
        stub_request(:post, "https://slack.com/api/conversations.history")
          .to_return(status: 500, body: {}.to_json)

          expect(transcript.load_chat_history).to be_falsey
      end

      it 'handles slack failure' do
        stub_request(:post, "https://slack.com/api/conversations.history")
          .to_return(status: 200, body: { ok: false }.to_json)

          expect(transcript.load_chat_history).to be_falsey
      end
    end

    context 'with thread_ts specified' do
      let(:thread_transcript) { described_class.new(channel_name: "#general", channel_id: "G1234", requested_thread_ts: "1501801629.052212") }

      before do
        stub_request(:post, "https://slack.com/api/conversations.replies")
          .with(body: hash_including(token: "abcde", channel: 'G1234', ts: "1501801629.052212"))
          .to_return(status: 200, body: { ok: true, messages: messages_fixture }.to_json)
        thread_transcript.load_chat_history
      end

      it 'includes messages in a thread' do
        expect(thread_transcript.messages.length).to eq(7)
      end

      it 'loads in chronological order' do # replies API presents messages in actual chronological order
        expect(thread_transcript.messages.first.ts).to eq('1501801665.062694')
      end

    end

    context 'with loaded messages' do
      before do
        stub_request(:post, "https://slack.com/api/conversations.history")
          .with(body: hash_including(token: "abcde", channel: 'G1234'))
          .to_return(status: 200, body: { ok: true, messages: messages_fixture }.to_json)
        transcript.load_chat_history
      end

      it 'ignores messages in a thread' do
        expect(transcript.messages.length).to eq(6)
      end

      it 'loads in chronological order' do # API presents in reverse chronological
        expect(transcript.messages.first.ts).to eq('1501093331.439776')
      end

      it 'handles bold text' do
        expect(transcript.messages.first.text).to eq("Let’s try some **bold text**")
      end

      it 'handles links' do
        expect(transcript.messages[2].text).to eq("So, who's interested in the new [discourse plugin](https://meta.discourse.org)?")
      end

      it 'includes attachments' do
        expect(transcript.messages[1].attachments.first).to eq("Discourse can now be integrated with Mattermost! - @david")
      end

      it 'can generate URL' do
        expect(transcript.messages.first.url).to eq("https://slack.com/archives/G1234/p1501093331439776")
      end

      it 'includes attachments in raw text' do
        transcript.set_first_message_by_ts('1501615820.949638')
        expect(transcript.first_message.raw_text).to eq("\n - Discourse can now be integrated with Mattermost! - @david\n")
      end

      it 'gives correct first and last messages' do
        expect(transcript.first_message_number).to eq(0)
        expect(transcript.last_message_number).to eq(transcript.messages.length - 1)

        expect(transcript.first_message.ts).to eq('1501093331.439776')
        expect(transcript.last_message.ts).to eq('1501801665.062694')
      end

      it 'can change first and last messages by index' do
        expect(transcript.set_first_message_by_index(999)).to be_falsey
        expect(transcript.set_first_message_by_index(1)).to be_truthy

        expect(transcript.set_last_message_by_index(-2)).to be_truthy

        expect(transcript.first_message.ts).to eq('1501615820.949638')
        expect(transcript.last_message.ts).to eq('1501801643.056375')
      end

      it 'can change first and last messages by ts' do
        expect(transcript.set_first_message_by_ts('blah')).to be_falsey
        expect(transcript.set_first_message_by_ts('1501615820.949638')).to be_truthy

        expect(transcript.set_last_message_by_ts('1501801629.052212')).to be_truthy

        expect(transcript.first_message_number).to eq(1)
        expect(transcript.last_message_number).to eq(2)
      end

      it 'can guess the first message' do
        expect(transcript.guess_first_message(skip_messages: 1)).to eq(true)
        expect(transcript.first_message.ts).to eq('1501801629.052212')
      end

      it 'handles usernames correctly' do
        expect(transcript.first_message.username).to eq('awesomeguy') # Normal user
        expect(transcript.messages[2].username).to eq(nil) # Unknown normal user
        expect(transcript.messages[1].username).to eq('Test Community') # Bot user
      end

      it 'handles avatars correctly' do
        expect(transcript.first_message.avatar).to eq("https://example.com/avatar") # Normal user
        expect(transcript.messages[1].avatar).to eq(nil) # Bot user
      end

      it 'creates a transcript correctly' do
        transcript.set_last_message_by_index(1)

        text = transcript.build_transcript

        # Rubocop doesn't like this, but we really do need trailing whitespace in the string
        # rubocop:disable TrailingWhitespace
        expected = <<~END
        [quote]
        [**View in #general on Slack**](https://slack.com/archives/G1234/p1501093331439776)

        ![awesomeguy] **@awesomeguy:** Let’s try some **bold text**

        **@Test Community:** 
        > Discourse can now be integrated with Mattermost! - @david

        [/quote]

        [awesomeguy]: https://example.com/avatar
        END
        # rubocop:enable TrailingWhitespace

        expect(text).to eq(expected)
      end

      it 'creates the slack UI correctly' do
        transcript.set_last_message_by_index(1)
        ui = transcript.build_slack_ui

        first_ui = ui[:attachments][0]
        last_ui = ui[:attachments][1]

        # The callback IDs are used to keep track of what the other option is
        expect(first_ui[:callback_id]).to eq(transcript.last_message.ts)
        expect(last_ui[:callback_id]).to eq(transcript.first_message.ts)

        # The timestamps should match up to the actual messages
        expect(first_ui[:ts]).to eq(transcript.first_message.ts)
        expect(last_ui[:ts]).to eq(transcript.last_message.ts)

        # Raw text should be used
        expect(first_ui[:text]).to eq(transcript.first_message.raw_text)
      end
    end
  end
end
