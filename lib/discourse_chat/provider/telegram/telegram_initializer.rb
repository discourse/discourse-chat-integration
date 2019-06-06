# frozen_string_literal: true

if Gem::Version.new(Discourse::VERSION::STRING) > Gem::Version.new("2.3.0.beta8")
  DiscourseEvent.on(:site_setting_changed) do |setting_name, old_value, new_value|
    isEnabledSetting = setting_name == 'chat_integration_telegram_enabled'
    isAccessToken =  setting_name == 'chat_integration_telegram_access_token'

    if (isEnabledSetting || isAccessToken)
      enabled = isEnabledSetting ? new_value == true : SiteSetting.chat_integration_telegram_enabled

      if enabled
        Scheduler::Defer.later("Setup Telegram Webhook") do
          DiscourseChat::Provider::TelegramProvider.setup_webhook()
        end
      end
    end
  end
else
  DiscourseEvent.on(site_setting_saved) do |sitesetting|
    isEnabledSetting = sitesetting.name == 'chat_integration_telegram_enabled'
    isAccessToken =  sitesetting.name == 'chat_integration_telegram_access_token'

    if (isEnabledSetting || isAccessToken)
      enabled = isEnabledSetting ? sitesetting.value == 't' : SiteSetting.chat_integration_telegram_enabled
      if enabled
        Scheduler::Defer.later("Setup Telegram Webhook") do
          DiscourseChat::Provider::TelegramProvider.setup_webhook()
        end
      end
    end
  end
end
