module DiscourseChat::Provider::TelegramProvider
  class TelegramCommandController < DiscourseChat::Provider::HookController
    requires_provider ::DiscourseChat::Provider::TelegramProvider::PROVIDER_NAME

    before_filter :telegram_token_valid?, only: :command

    skip_before_filter :check_xhr,
                       :preload_json,
                       :verify_authenticity_token,
                       :redirect_to_login_if_required,
                       only: :command

    def command

      # If it's a new message (telegram also sends hooks for other reasons that we don't care about)
      if params.key?('message')
        chat_id = params['message']['chat']['id']

        message_text = process_command(params['message'])

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

      channel = DiscourseChat::Channel.with_provider(provider).with_data_value('chat_id',chat_id).first

      if channel.nil?
        return  I18n.t(
          "chat_integration.provider.telegram.unknown_chat",
          site_title: CGI::escapeHTML(SiteSetting.title),
          chat_id: chat_id,
        )
      end
      
      # If slash commands disabled, send a generic message
      if !SiteSetting.chat_integration_telegram_enable_slash_commands
        return  I18n.t(
          "chat_integration.provider.telegram.known_chat",
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
    engine_name DiscourseChat::PLUGIN_NAME+"-telegram"
    isolate_namespace DiscourseChat::Provider::TelegramProvider
  end

  TelegramEngine.routes.draw do
  	post "command/:token" => "telegram_command#command"
  end
end