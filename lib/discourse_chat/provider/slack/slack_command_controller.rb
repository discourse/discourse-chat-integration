# frozen_string_literal: true

module DiscourseChat::Provider::SlackProvider
  class SlackCommandController < DiscourseChat::Provider::HookController
    requires_provider ::DiscourseChat::Provider::SlackProvider::PROVIDER_NAME

    before_action :slack_token_valid?, only: :command
    before_action :slack_payload_token_valid?, only: :interactive

    skip_before_action :check_xhr,
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

      channel = DiscourseChat::Channel.with_provider(provider)
        .with_data_value('identifier', channel_id)
        .first

      channel ||= DiscourseChat::Channel.create!(
        provider: provider,
        data: { identifier: channel_id }
      )

      if tokens[0] == 'post'
        process_post_request(channel, tokens, params[:channel_id], channel_id, params[:response_url])
      else
        { text: ::DiscourseChat::Helper.process_command(channel, tokens) }
      end
    end

    def process_post_request(channel, tokens, slack_channel_id, channel_name, response_url)
      if SiteSetting.chat_integration_slack_access_token.empty?
        return { text: I18n.t("chat_integration.provider.slack.transcript.api_required") }
      end

      Scheduler::Defer.later "Processing slack transcript request" do
        requested_messages = nil
        first_message_ts = nil
        requested_thread_ts = nil

        thread_url_regex = /^https:\/\/\S+\.slack\.com\/archives\/\S+\/p[0-9]{16}\?thread_ts=([0-9]{10}.[0-9]{6})\S*$/
        slack_url_regex = /^https:\/\/\S+\.slack\.com\/archives\/\S+\/p([0-9]{16})\/?$/

        if tokens.size > 2 && tokens[1] == "thread" && match = slack_url_regex.match(tokens[2])
          requested_thread_ts = match.captures[0].insert(10, '.')
        elsif tokens.size > 1 && match = thread_url_regex.match(tokens[1])
          requested_thread_ts = match.captures[0]
        elsif tokens.size > 1 && match = slack_url_regex.match(tokens[1])
          first_message_ts = match.captures[0].insert(10, '.')
        elsif tokens.size > 1
          begin
            requested_messages = Integer(tokens[1], 10)
          rescue ArgumentError
            break { text: I18n.t("chat_integration.provider.slack.parse_error") }
          end
        end

        error_message = { text: I18n.t("chat_integration.provider.slack.transcript.error") }

        break error_message unless transcript = SlackTranscript.new(channel_name: channel_name, channel_id: slack_channel_id, requested_thread_ts: requested_thread_ts)
        break error_message unless transcript.load_user_data
        break error_message unless transcript.load_chat_history

        if first_message_ts
          break error_message unless transcript.set_first_message_by_ts(first_message_ts)
        elsif requested_messages
          transcript.set_first_message_by_index(-requested_messages)
        else
          transcript.set_first_message_by_index(-10) unless transcript.guess_first_message
        end

        http = Net::HTTP.new("slack.com", 443)
        http.use_ssl = true
        req = Net::HTTP::Post.new(URI(response_url), 'Content-Type' => 'application/json')
        req.body = transcript.build_slack_ui.to_json
        response = http.request(req)
      end

      { text: I18n.t("chat_integration.provider.slack.transcript.loading") }
    end

    def interactive
      json = JSON.parse(params[:payload], symbolize_names: true)
      process_interactive(json)

      render json: { text: I18n.t("chat_integration.provider.slack.transcript.loading") }
    end

    def process_interactive(json)
      action_name = json[:actions][0][:name]

      constant_val = json[:callback_id]
      changed_val = json[:actions][0][:selected_options][0][:value]

      first_message = (action_name == 'first_message') ? changed_val : constant_val
      last_message = (action_name == 'first_message') ? constant_val : changed_val

      error_message = { text: I18n.t("chat_integration.provider.slack.transcript.error") }

      Scheduler::Defer.later "Processing slack transcript update" do
        break error_message unless transcript = SlackTranscript.new(channel_name: "##{json[:channel][:name]}", channel_id: json[:channel][:id])
        break error_message unless transcript.load_user_data
        break error_message unless transcript.load_chat_history

        break error_message unless transcript.set_first_message_by_ts(first_message)
        break error_message unless transcript.set_last_message_by_ts(last_message)

        http = Net::HTTP.new("slack.com", 443)
        http.use_ssl = true
        req = Net::HTTP::Post.new(URI(json[:response_url]), 'Content-Type' => 'application/json')
        req.body = transcript.build_slack_ui.to_json
        response = http.request(req)
      end
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
