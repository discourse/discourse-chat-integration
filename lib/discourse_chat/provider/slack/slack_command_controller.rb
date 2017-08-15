module DiscourseChat::Provider::SlackProvider
  class SlackCommandController < DiscourseChat::Provider::HookController
    requires_provider ::DiscourseChat::Provider::SlackProvider::PROVIDER_NAME

    before_filter :slack_token_valid?, only: :command
    before_filter :slack_payload_token_valid?, only: :interactive

    skip_before_filter :check_xhr,
                       :preload_json,
                       :verify_authenticity_token,
                       :redirect_to_login_if_required,
                       only: [:command, :interactive]

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
        return process_post_request(channel, tokens, params[:channel_id], channel_id)
      end

      return { text: ::DiscourseChat::Helper.process_command(channel, tokens) }

    end

    def process_post_request(channel, tokens, slack_channel_id, channel_name)
      if SiteSetting.chat_integration_slack_access_token.empty?
        return { text: I18n.t("chat_integration.provider.slack.transcript.api_required") }
      end

      requested_messages = 10

      first_message_ts = nil
      slack_url_regex = /^https:\/\/\S+\.slack\.com\/archives\/\S+\/p([0-9]{16})\/?$/
      if tokens.size > 1 && match = slack_url_regex.match(tokens[1])
        first_message_ts = match.captures[0].insert(10, '.')
      elsif tokens.size > 1
        begin
          requested_messages = Integer(tokens[1], 10)
        rescue ArgumentError
          return { text: I18n.t("chat_integration.provider.slack.parse_error") }
        end
      end

      error_message = { text: I18n.t("chat_integration.provider.slack.transcript.error") }

      return error_message unless transcript = SlackTranscript.new(channel_name: channel_name)
      return error_message unless transcript.load_user_data
      return error_message unless transcript.load_chat_history(slack_channel_id: slack_channel_id)

      if first_message_ts
        return error_message unless transcript.set_first_message_by_ts(first_message_ts)
      else
        return error_message unless transcript.set_first_message_by_index(-requested_messages)
      end

      return transcript.build_slack_ui

    end

    def interactive
      json = JSON.parse(params[:payload], symbolize_names: true)

      render json: process_interactive(json)
    end

    def process_interactive(json)
      action_name = json[:actions][0][:name]

      constant_val = json[:callback_id]
      changed_val = json[:actions][0][:selected_options][0][:value]

      first_message = (action_name == 'first_message') ? changed_val : constant_val
      last_message = (action_name == 'first_message') ? constant_val : changed_val

      error_message = { text: I18n.t("chat_integration.provider.slack.transcript.error") }

      return error_message unless transcript = SlackTranscript.new(channel_name: "##{json[:channel][:name]}")
      return error_message unless transcript.load_user_data
      return error_message unless transcript.load_chat_history(slack_channel_id: json[:channel][:id])

      return error_message unless transcript.set_first_message_by_ts(first_message)
      return error_message unless transcript.set_last_message_by_ts(last_message)

      return transcript.build_slack_ui
    end

    def slack_token_valid?
      params.require(:token)

      if SiteSetting.chat_integration_slack_incoming_webhook_token.blank? ||
         SiteSetting.chat_integration_slack_incoming_webhook_token != params[:token]

        raise Discourse::InvalidAccess.new
      end
    end

    def slack_payload_token_valid?
      params.require(:payload)

      json = JSON.parse(params[:payload], symbolize_names: true)

      if SiteSetting.chat_integration_slack_incoming_webhook_token.blank? ||
         SiteSetting.chat_integration_slack_incoming_webhook_token != json[:token]

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
    post "interactive" => "slack_command#interactive"
  end

end
