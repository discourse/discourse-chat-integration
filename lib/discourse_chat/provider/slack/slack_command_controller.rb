module DiscourseChat::Provider::SlackProvider
  class SlackCommandController < DiscourseChat::Provider::HookController
    requires_provider ::DiscourseChat::Provider::SlackProvider::PROVIDER_NAME

    before_filter :slack_token_valid?, only: :command

    skip_before_filter :check_xhr,
                       :preload_json,
                       :verify_authenticity_token,
                       :redirect_to_login_if_required,
                       only: :command

    def command
      message = process_command(params)

      render json: message
    end

    def process_command(params)

      tokens = params[:text].split(" ")

      # channel name fix
      channel_id =
        case params[:channel_name]
        when 'directmessage'
          "@#{params[:user_name]}"
        when 'privategroup'
          params[:channel_id]
        else
          "##{params[:channel_name]}"
        end

      provider = DiscourseChat::Provider::SlackProvider::PROVIDER_NAME

      channel = DiscourseChat::Channel.with_provider(provider).with_data_value('identifier', channel_id).first

      # Create channel if doesn't exist
      channel ||= DiscourseChat::Channel.create!(provider: provider, data: { identifier: channel_id })

      if tokens[0] == 'post'
        return process_post_request(channel, tokens, params[:channel_id])
      end

      return { text: ::DiscourseChat::Helper.process_command(channel, tokens)}

    end

    def process_post_request(channel, tokens, slack_channel_id)
      if SiteSetting.chat_integration_slack_access_token.empty?
        return I18n.t("chat_integration.provider.slack.api_required")
      end

      http = Net::HTTP.new("slack.com", 443)
      http.use_ssl = true

      messages_to_load = 10

      if tokens.size > 1
        begin
          messages_to_load = Integer(tokens[1], 10)
        rescue ArgumentError
          return I18n.t("chat_integration.provider.slack.parse_error")
        end
      end

      error_text = I18n.t("chat_integration.provider.slack.transcript_error")

      # Load the user data (we need this to change user IDs into usernames)
      req = Net::HTTP::Post.new(URI('https://slack.com/api/users.list'))
      req.set_form_data(token: SiteSetting.chat_integration_slack_access_token)
      response = http.request(req)
      return error_text unless response.kind_of? Net::HTTPSuccess
      json = JSON.parse(response.body)
      return error_text unless json['ok']
      raw_users = json

      # Now load the chat message history
      req = Net::HTTP::Post.new(URI('https://slack.com/api/channels.history'))

      data = {
        token: SiteSetting.chat_integration_slack_access_token,
        channel: slack_channel_id,
        count: messages_to_load
      }

      req.set_form_data(data)
      response = http.request(req)
      return error_text unless response.kind_of? Net::HTTPSuccess
      json = JSON.parse(response.body)
      return error_text unless json['ok']
      raw_history = json

      transcript = SlackTranscript.new(raw_history, raw_users, slack_channel_id)

      post_content = transcript.build_transcript

      secret = DiscourseChat::Helper.save_transcript(post_content)

      link = "#{Discourse.base_url}/chat-transcript/#{secret}"

      return { text: "<#{link}|#{I18n.t("chat_integration.provider.slack.post_to_discourse")}>",
             }

    end

    def slack_token_valid?
      params.require(:token)

      if SiteSetting.chat_integration_slack_incoming_webhook_token.blank? ||
         SiteSetting.chat_integration_slack_incoming_webhook_token != params[:token]

        raise Discourse::InvalidAccess.new
      end
    end
  end

  class SlackEngine < ::Rails::Engine
    engine_name DiscourseChat::PLUGIN_NAME + "-slack"
    isolate_namespace DiscourseChat::Provider::SlackProvider
  end

  SlackEngine.routes.draw do
    post "command" => "slack_command#command"
  end

end
