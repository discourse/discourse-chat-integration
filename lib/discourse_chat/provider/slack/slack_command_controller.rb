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
      text = process_command(params)

      render json: { text: text }
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

      return ::DiscourseChat::Helper.process_command(channel, tokens)

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
      users = json["members"]

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

      first_post_link = "https://slack.com/archives/#{slack_channel_id}/p"
      first_post_link += json["messages"].reverse.first["ts"].gsub('.', '')

      post_content = ""

      post_content << "[quote]\n"

      post_content << "[**#{I18n.t('chat_integration.provider.slack.view_on_slack')}**](#{first_post_link})\n"

      users_in_transcript = []
      last_user = ''
      json["messages"].reverse.each do |message|
        next unless message["type"] == "message"

        username = ""
        if user_id = message["user"]
          user = users.find { |u| u["id"] == user_id }
          users_in_transcript << user
          username = user["name"]
        elsif message.key?("username")
          username = message["username"]
        end

        same_user = last_user == username
        last_user = username

        if not same_user
          post_content << "\n"
          post_content << "![#{username}] " if message["user"]
          post_content << "**@#{username}:** "
        end

        text = message["text"]

        # Format links (don't worry about special cases @ # !)
        text.gsub!(/<(.*?)>/) do |match|
          group = $1
          parts = group.split('|')
          link = parts[0].start_with?('@', '#', '!') ? '' : parts[0]
          text = parts.length > 1 ? parts[1] : parts[0]
          "[#{text}](#{link})"
        end

        # Add an extra * to each side for bold
        text.gsub!(/\*(.*?)\*/) do |match|
          "*#{match}*"
        end

        post_content << message["text"]

        if message.key?("attachments")
          message["attachments"].each do |attachment|
            next unless attachment.key?("fallback")
            post_content << "\n> #{attachment["fallback"]}\n"
          end
        end

        post_content << "\n"
      end

      post_content << "[/quote]\n\n"

      users_in_transcript.uniq.each do |user|
        post_content << "[#{user["name"]}]: #{user["profile"]["image_24"]}\n" if user
      end

      secret = DiscourseChat::Helper.save_transcript(post_content)

      link = "#{Discourse.base_url}/chat-transcript/#{secret}"

      return "<#{link}|#{I18n.t("chat_integration.provider.slack.post_to_discourse")}>"

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
