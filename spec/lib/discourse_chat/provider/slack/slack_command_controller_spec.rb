require 'rails_helper'

describe 'Slack Command Controller', type: :request do
  let(:category) { Fabricate(:category) }
  let(:tag) { Fabricate(:tag) }
  let(:tag2) { Fabricate(:tag) }
  let!(:chan1) { DiscourseChat::Channel.create!(provider: 'slack', data: { identifier: '#welcome' }) }

  describe 'with plugin disabled' do
    it 'should return a 404' do
      post '/chat-integration/slack/command.json'
      expect(response.status).to eq(404)
    end
  end

  describe 'with plugin enabled and provider disabled' do
    before do
      SiteSetting.chat_integration_enabled = true
      SiteSetting.chat_integration_slack_enabled = false
    end

    it 'should return a 404' do
      post '/chat-integration/slack/command.json'
      expect(response.status).to eq(404)
    end
  end

  describe 'slash commands endpoint' do
    before do
      SiteSetting.chat_integration_enabled = true
      SiteSetting.chat_integration_slack_outbound_webhook_url = "https://hooks.slack.com/services/abcde"
      SiteSetting.chat_integration_slack_enabled = true
    end

    describe 'when forum is private' do
      it 'should not redirect to login page' do
        SiteSetting.login_required = true
        token = 'sometoken'
        SiteSetting.chat_integration_slack_incoming_webhook_token = token

        post '/chat-integration/slack/command.json', params: {
          text: 'help', token: token
        }

        expect(response.status).to eq(200)
      end
    end

    describe 'when the token is invalid' do
      it 'should raise the right error' do
        expect { post '/chat-integration/slack/command.json', params: { text: 'help' } }
          .to raise_error(ActionController::ParameterMissing)
      end
    end

    describe 'when incoming webhook token has not been set' do
      it 'should raise the right error' do
        post '/chat-integration/slack/command.json', params: {
          text: 'help', token: 'some token'
        }

        expect(response.status).to eq(403)
      end
    end

    describe 'when token is valid' do
      let(:token) { "Secret Sauce" }

      # No need to test every single command here, that's tested
      # by helper_spec upstream

      before do
        SiteSetting.chat_integration_slack_incoming_webhook_token = token
      end

      describe 'add new rule' do

        it 'should add a new rule correctly' do
          post "/chat-integration/slack/command.json", params: {
            text: "watch #{category.slug}",
            channel_name: 'welcome',
            token: token
          }

          json = JSON.parse(response.body)

          expect(json["text"]).to eq(I18n.t("chat_integration.provider.slack.create.created"))

          rule = DiscourseChat::Rule.all.first
          expect(rule.channel).to eq(chan1)
          expect(rule.filter).to eq('watch')
          expect(rule.category_id).to eq(category.id)
          expect(rule.tags).to eq(nil)
        end

        context 'from an unknown channel' do
          it 'creates the channel' do
            post "/chat-integration/slack/command.json", params: {
              text: "watch #{category.slug}",
              channel_name: 'general',
              token: token
            }

            json = JSON.parse(response.body)

            expect(json["text"]).to eq(I18n.t("chat_integration.provider.slack.create.created"))

            chan = DiscourseChat::Channel.with_provider('slack').with_data_value('identifier', '#general').first
            expect(chan.provider).to eq('slack')

            rule = chan.rules.first
            expect(rule.filter).to eq('watch')
            expect(rule.category_id).to eq(category.id)
            expect(rule.tags).to eq(nil)
          end
        end
      end

      describe 'post transcript' do
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

        before do
          SiteSetting.chat_integration_slack_access_token = 'abcde'
        end

        context "with valid slack responses" do
          before do
            stub1 = stub_request(:post, "https://slack.com/api/users.list").to_return(body: '{"ok":true,"members":[{"id":"U5Z773QLS","name":"david","profile":{"icon_24":"https://example.com/avatar"}}]}')
            stub2 = stub_request(:post, "https://slack.com/api/channels.history").to_return(body: { ok: true, messages: messages_fixture }.to_json)
          end

          it 'generates the transcript UI properly' do
            command_stub = stub_request(:post, "https://slack.com/commands/1234")
              .with(body: /attachments/)
              .to_return(body: { ok: true }.to_json)

            post "/chat-integration/slack/command.json", params: {
              text: "post",
              response_url: 'https://hooks.slack.com/commands/1234',
              channel_name: 'general',
              channel_id: 'C6029G78F',
              token: token
            }

            expect(command_stub).to have_been_requested
          end

          it 'can select by url' do
            command_stub = stub_request(:post, "https://slack.com/commands/1234")
              .with(body: /1501801629\.052212/)
              .to_return(body: { ok: true }.to_json)

            post "/chat-integration/slack/command.json", params: {
              text: "post https://sometestslack.slack.com/archives/C6029G78F/p1501801629052212",
              response_url: 'https://hooks.slack.com/commands/1234',
              channel_name: 'general',
              channel_id: 'C6029G78F',
              token: token
            }

            expect(command_stub).to have_been_requested
          end

          it 'can select by count' do
            command_stub = stub_request(:post, "https://slack.com/commands/1234")
              .with(body: /1501801629\.052212/)
              .to_return(body: { ok: true }.to_json)

            post "/chat-integration/slack/command.json", params: {
              text: "post 4",
              response_url: 'https://hooks.slack.com/commands/1234',
              channel_name: 'general',
              channel_id: 'C6029G78F',
              token: token
            }

            expect(command_stub).to have_been_requested
          end

          it 'can auto select' do
            command_stub = stub_request(:post, "https://slack.com/commands/1234")
              .with(body: /1501615820\.949638/)
              .to_return(body: { ok: true }.to_json)

            post "/chat-integration/slack/command.json", params: {
              text: "post",
              response_url: 'https://hooks.slack.com/commands/1234',
              channel_name: 'general',
              channel_id: 'C6029G78F',
              token: token
            }

            expect(command_stub).to have_been_requested
          end
        end

        it 'deals with failed API calls correctly' do
          stub1 = stub_request(:post, "https://slack.com/api/users.list").to_return(status: 403)

          post "/chat-integration/slack/command.json", params: {
            text: "post 2",
            response_url: 'https://hooks.slack.com/commands/1234',
            channel_name: 'general',
            channel_id: 'C6029G78F',
            token: token
          }

          json = JSON.parse(response.body)

          expect(json["text"]).to include(I18n.t("chat_integration.provider.slack.transcript.error"))
        end

        it 'errors correctly if there is no api key' do
          SiteSetting.chat_integration_slack_access_token = ''

          post "/chat-integration/slack/command.json", params: {
            text: "post 2",
            response_url: 'https://hooks.slack.com/commands/1234',
            channel_name: 'general',
            channel_id: 'C6029G78F',
            token: token
          }

          json = JSON.parse(response.body)

          expect(json["text"]).to include(I18n.t("chat_integration.provider.slack.transcript.api_required"))
        end
      end

    end
  end
end
