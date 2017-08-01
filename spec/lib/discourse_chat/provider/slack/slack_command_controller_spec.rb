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

        post '/chat-integration/slack/command.json', text: 'help', token: token

        expect(response.status).to eq(200)
      end
    end

    describe 'when the token is invalid' do
      it 'should raise the right error' do
        expect { post '/chat-integration/slack/command.json', text: 'help' }
          .to raise_error(ActionController::ParameterMissing)
      end
    end

    describe 'when incoming webhook token has not been set' do
      it 'should raise the right error' do
        post '/chat-integration/slack/command.json', text: 'help', token: 'some token'

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
          post "/chat-integration/slack/command.json",
            text: "watch #{category.slug}",
            channel_name: 'welcome',
            token: token

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
            post "/chat-integration/slack/command.json",
            text: "watch #{category.slug}",
            channel_name: 'general',
            token: token

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
        before do
          SiteSetting.chat_integration_slack_access_token = 'abcde'
        end

        it 'generates a transcript properly' do
          stub1 = stub_request(:post, "https://slack.com/api/users.list").to_return(body: '{"ok":true,"members":[{"id":"U5Z773QLS","name":"david","profile":{"icon_24":"https://example.com/avatar"}}]}')
          stub2 = stub_request(:post, "https://slack.com/api/channels.history").to_return(body: '{"ok":true,"messages":[{"type":"message","user":"U5Z773QLS","text":"And this is a slack message with an attachment: <https:\/\/meta.discourse.org>","attachments":[{"title":"Discourse Meta","title_link":"https:\/\/meta.discourse.org","text":"Discussion about the next-generation open source Discourse forum software","fallback":"Discourse Meta","thumb_url":"https:\/\/discourse-meta.s3-us-west-1.amazonaws.com\/original\/3X\/c\/b\/cb4bec8901221d4a646e45e1fa03db3a65e17f59.png","from_url":"https:\/\/meta.discourse.org","thumb_width":350,"thumb_height":349,"service_icon":"https:\/\/discourse-meta.s3-us-west-1.amazonaws.com\/original\/3X\/c\/b\/cb4bec8901221d4a646e45e1fa03db3a65e17f59.png","service_name":"meta.discourse.org","id":1}],"ts":"1500910064.045243"},{"type":"message","user":"U5Z773QLS","text":"Hello world, this is a slack message","ts":"1500910051.036792"}],"has_more":true}')

          post "/chat-integration/slack/command.json",
            text: "post 2",
            channel_name: 'general',
            channel_id: 'C6029G78F',
            token: token

          json = JSON.parse(response.body)

          expect(json["text"]).to include(I18n.t("chat_integration.provider.slack.post_to_discourse"))
        end

        it 'deals with failed API calls correctly' do
          stub1 = stub_request(:post, "https://slack.com/api/users.list").to_return(status: 403)

          post "/chat-integration/slack/command.json",
            text: "post 2",
            channel_name: 'general',
            channel_id: 'C6029G78F',
            token: token

          json = JSON.parse(response.body)

          expect(json["text"]).to include(I18n.t("chat_integration.provider.slack.transcript_error"))
        end

        it 'errors correctly if there is no api key' do
          SiteSetting.chat_integration_slack_access_token = ''

          post "/chat-integration/slack/command.json",
            text: "post 2",
            channel_name: 'general',
            channel_id: 'C6029G78F',
            token: token

          json = JSON.parse(response.body)

          expect(json["text"]).to include(I18n.t("chat_integration.provider.slack.api_required"))
        end
      end

    end
  end
end
