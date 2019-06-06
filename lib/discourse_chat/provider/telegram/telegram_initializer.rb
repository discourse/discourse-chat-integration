# frozen_string_literal: true

event =
  if Gem::Version.new(Discourse::VERSION::STRING) > Gem::Version.new("2.3.0.beta8")
    :site_setting_changed
  else
    :site_setting_saved
  end

DiscourseEvent.on(event) do |sitesetting|
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
