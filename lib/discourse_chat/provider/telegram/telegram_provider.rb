module DiscourseChat
  module Provider
    module TelegramProvider
    	include Provider

      PROVIDER_NAME = "telegram".freeze
      PROVIDER_ENABLED_SETTING = :chat_integration_telegram_enabled
    end
  end
end

require_relative "telegram_command_controller.rb"