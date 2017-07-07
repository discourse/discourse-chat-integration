require 'rails_helper'

describe 'Slack Command Controller', type: :request do
  let(:category) { Fabricate(:category) }
  let(:tag) { Fabricate(:tag) }
  let(:tag2) { Fabricate(:tag) }

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

      before do
        SiteSetting.chat_integration_slack_incoming_webhook_token = token
      end

      describe 'add new rule' do
        # Not testing how filters are merged here, that's done upstream in helper_spec
        # We just want to make sure the slash commands are being interpretted correctly

        it 'should add a new rule correctly' do
          post "/chat-integration/slack/command.json",
            text: "watch #{category.slug}",
            channel_name: 'welcome',
            token: token

          json = JSON.parse(response.body)

          expect(json["text"]).to eq(I18n.t("chat_integration.provider.slack.create.created"))

          rule = DiscourseChat::Rule.all.first
          expect(rule.provider).to eq('slack')
          expect(rule.channel).to eq('#welcome')
          expect(rule.filter).to eq('watch')
          expect(rule.category_id).to eq(category.id)
          expect(rule.tags).to eq(nil)
        end

        it 'should work with all three filter types' do
          post "/chat-integration/slack/command.json",
            text: "watch #{category.slug}",
            channel_name: 'welcome',
            token: token

          rule = DiscourseChat::Rule.all.first
          expect(rule.filter).to eq('watch')

          post "/chat-integration/slack/command.json",
            text: "follow #{category.slug}",
            channel_name: 'welcome',
            token: token

          rule = DiscourseChat::Rule.all.first
          expect(rule.filter).to eq('follow')

          post "/chat-integration/slack/command.json",
            text: "mute #{category.slug}",
            channel_name: 'welcome',
            token: token

          rule = DiscourseChat::Rule.all.first
          expect(rule.filter).to eq('mute')
        end

        it 'errors on incorrect categories' do
          post "/chat-integration/slack/command.json",
            text: "watch blah",
            channel_name: 'welcome',
            token: token

          expect(response).to be_success
          json = JSON.parse(response.body)
          expect(json["text"]).to eq(I18n.t("chat_integration.provider.slack.not_found.category", name:'blah', list:'uncategorized'))
        end
      
        context 'with tags enabled' do
          before do
            SiteSetting.tagging_enabled = true
          end

          it 'should add a new tag rule correctly' do
            post "/chat-integration/slack/command.json",
              text: "watch tag:#{tag.name}",
              channel_name: 'welcome',
              token: token

            expect(response).to be_success

            json = JSON.parse(response.body)

            expect(json["text"]).to eq(I18n.t("chat_integration.provider.slack.create.created"))

            rule = DiscourseChat::Rule.all.first
            expect(rule.provider).to eq('slack')
            expect(rule.channel).to eq('#welcome')
            expect(rule.filter).to eq('watch')
            expect(rule.category_id).to eq(nil)
            expect(rule.tags).to eq([tag.name])
          end

          it 'should work with a category and multiple tags' do
            post "/chat-integration/slack/command.json",
              text: "watch #{category.slug} tag:#{tag.name} tag:#{tag2.name}",
              channel_name: 'welcome',
              token: token

            expect(response).to be_success

            json = JSON.parse(response.body)

            expect(json["text"]).to eq(I18n.t("chat_integration.provider.slack.create.created"))

            rule = DiscourseChat::Rule.all.first
            expect(rule.provider).to eq('slack')
            expect(rule.channel).to eq('#welcome')
            expect(rule.filter).to eq('watch')
            expect(rule.category_id).to eq(category.id)
            expect(rule.tags).to contain_exactly(tag.name, tag2.name)
          end

          it 'errors on incorrect tags' do
            post "/chat-integration/slack/command.json",
              text: "watch tag:blah",
              channel_name: 'welcome',
              token: token

            expect(response).to be_success

            json = JSON.parse(response.body)

            expect(json["text"]).to eq(I18n.t("chat_integration.provider.slack.not_found.tag", name:"blah"))
          end
        end
      end

      describe 'remove rule' do
        it 'removes the rule' do
          rule1 = DiscourseChat::Rule.new({provider: 'slack',
                                          channel: '#welcome',
                                          filter: 'watch',
                                          category_id: category.id,
                                          tags: [tag.name, tag2.name]
                                        }).save!

          expect(DiscourseChat::Rule.all.size).to eq(1)
          post "/chat-integration/slack/command.json",
              text: "remove 1",
              channel_name: 'welcome',
              token: token

          expect(response).to be_success

          json = JSON.parse(response.body)

          expect(json["text"]).to eq(I18n.t("chat_integration.provider.slack.delete.success"))

          expect(DiscourseChat::Rule.all.size).to eq(0)
        end

        it 'errors correctly' do
          post "/chat-integration/slack/command.json",
              text: "remove 1",
              channel_name: 'welcome',
              token: token

          expect(response).to be_success

          json = JSON.parse(response.body)

          expect(json["text"]).to eq(I18n.t("chat_integration.provider.slack.delete.error"))          
        end
      end

      describe 'help command' do
        it 'should return the right response' do
          post '/chat-integration/slack/command.json', text: "help", channel_name: "welcome", token: token

          expect(response).to be_success

          json = JSON.parse(response.body)

          expect(json["text"]).to eq(I18n.t("chat_integration.provider.slack.help"))
        end
      end

      describe 'status command' do
        # No need to test this with different combinations of rules
        # That's done upstream in helper_spec 

        it 'should return the right response' do
          post '/chat-integration/slack/command.json',
            text: "status",
            channel_name: "welcome",
            token: token

          expect(response).to be_success

          json = JSON.parse(response.body)

          expect(json["text"]).to eq(DiscourseChat::Helper.status_for_channel('slack','#welcome'))
        end
      end

      describe 'unknown command' do
        # No need to test this with different combinations of rules
        # That's done upstream in helper_spec 

        it 'should return the right response' do
          post '/chat-integration/slack/command.json',
            text: "somerandomtext",
            channel_name: "welcome",
            token: token

          expect(response).to be_success

          json = JSON.parse(response.body)

          expect(json["text"]).to eq(I18n.t("chat_integration.provider.slack.parse_error"))
        end
      end

    end
  end
end
