module DiscourseChat::Provider::TelegramProvider
  class TelegramCommandController < DiscourseChat::Provider::HookController
    requires_provider ::DiscourseChat::Provider::TelegramProvider::PROVIDER_NAME

    before_action :telegram_token_valid?, only: :command

    skip_before_action :check_xhr,
                       :preload_json,
                       :verify_authenticity_token,
                       :redirect_to_login_if_required,
                       only: :command

    def command

      # If it's a new message (telegram also sends hooks for other reasons that we don't care about)
      # if params.key?('message')
      #   chat_id = params['message']['chat']['id']
      #
      #   message_text = process_command(params['message'])
      #
      #   message = {
      #     chat_id: chat_id,
      #     text: message_text,
      #     parse_mode: "html",
      #     disable_web_page_preview: true,
      #   }
      #
      #   DiscourseChat::Provider::TelegramProvider.sendMessage(message)
      # THIS IF BLOCK IS COMMENTED TO DISABLE BOT MESSAGE ON REPLYING MESSAGE ETC.

      if params.key?('channel_post') && params['channel_post']['text'].include?('/getchatid')
        chat_id = params['channel_post']['chat']['id']

        message_text = I18n.t(
          "chat_integration.provider.telegram.unknown_chat",
          site_title: CGI::escapeHTML(SiteSetting.title),
          chat_id: chat_id,
        )

        message = {
          chat_id: chat_id,
          text: message_text,
          parse_mode: "html",
          disable_web_page_preview: true,
        }

        DiscourseChat::Provider::TelegramProvider.sendMessage(message)
      end

      # Always give telegram a success message, otherwise we'll stop receiving webhooks
      data = {
        success: true
      }
      render json: data
    end

    def process_command(message)
      chat_id = params['message']['chat']['id']

      provider = DiscourseChat::Provider::TelegramProvider::PROVIDER_NAME

      channel = DiscourseChat::Channel.with_provider(provider).with_data_value('chat_id', chat_id).first

      text_key = "unknown_chat" if channel.nil?
      # If slash commands disabled, send a generic message
      text_key = "known_chat" if !SiteSetting.chat_integration_telegram_enable_slash_commands
      text_key = "help" if message['text'].blank?

      if text_key.present?
        return  I18n.t(
          "chat_integration.provider.telegram.#{text_key}",
          site_title: CGI::escapeHTML(SiteSetting.title),
          chat_id: chat_id,
        )
      end

      tokens = message['text'].split(" ")

      tokens[0][0] = '' # Remove the slash from the first token
      tokens[0] = tokens[0].split('@')[0] # Remove the bot name from the command (necessary for group chats)

      return ::DiscourseChat::Helper.process_command(channel, tokens)
    end

    def telegram_token_valid?
      params.require(:token)

      if SiteSetting.chat_integration_telegram_secret.blank? ||
         SiteSetting.chat_integration_telegram_secret != params[:token]

        raise Discourse::InvalidAccess.new
      end
    end
  end

  class TelegramEngine < ::Rails::Engine
    engine_name DiscourseChat::PLUGIN_NAME + "-telegram"
    isolate_namespace DiscourseChat::Provider::TelegramProvider
  end

  TelegramEngine.routes.draw do
    post "command/:token" => "telegram_command#command"
  end
end
