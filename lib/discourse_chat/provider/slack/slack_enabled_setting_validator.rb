class ChatIntegrationSlackEnabledSettingValidator
  def initialize(opts={})
    @opts = opts
  end

  def valid_value?(val)
    return true if val == 'f' or val == false
    return false if SiteSetting.chat_integration_slack_outbound_webhook_url.blank? && SiteSetting.chat_integration_slack_access_token.blank?
    true
  end

  def error_message
      I18n.t('site_settings.errors.chat_integration_slack_api_configs_are_empty')
  end

end
