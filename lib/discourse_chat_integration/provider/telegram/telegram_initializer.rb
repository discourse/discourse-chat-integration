# frozen_string_literal: true

DiscourseEvent.on(:site_setting_changed) do |setting_name, old_value, new_value|
  isEnabledSetting = setting_name == :chat_integration_telegram_enabled
  isAccessToken = setting_name == :chat_integration_telegram_access_token

  if (isEnabledSetting || isAccessToken)
    enabled = isEnabledSetting ? new_value == true : SiteSetting.chat_integration_telegram_enabled

    if enabled && SiteSetting.chat_integration_telegram_access_token.present?
      Scheduler::Defer.later("Setup Telegram Webhook") do
        DiscourseChatIntegration::Provider::TelegramProvider.setup_webhook
      end
    end
  end
end
