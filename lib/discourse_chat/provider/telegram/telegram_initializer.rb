DiscourseEvent.on(:site_setting_saved) do |sitesetting|
  isEnabledSetting =  sitesetting.name == 'chat_integration_telegram_enabled' 
  isAccessToken =  sitesetting.name == 'chat_integration_telegram_access_token' 

  if (isEnabledSetting or isAccessToken)
    enabled = isEnabledSetting ? sitesetting.value == 't' : SiteSetting.chat_integration_telegram_enabled
    # Rails.logger.error("JOB ENQUEUED"+sitesetting.value+SiteSetting.chat_integration_telegram_enabled.to_s)
    if enabled
      Scheduler::Defer.later("Setup Telegram Webhook") do
        DiscourseChat::Provider::TelegramProvider.setup_webhook()
      end
    end
  end
end