module DiscourseChat
  module Provider
    def self.providers
      constants.select do |constant|
        constant.to_s =~ /Provider$/
      end.map(&method(:const_get))
    end

    def self.enabled_providers
      self.providers.select do |provider|
        self.is_enabled(provider)
      end
    end

    def self.get_by_name(name)
      self.providers.find{|p| p::PROVIDER_NAME == name}
    end

    def self.is_enabled(provider)
      if defined? provider::PROVIDER_ENABLED_SETTING 
        SiteSetting.send(provider::PROVIDER_ENABLED_SETTING)
      else
        false
      end
    end

  end
end

require_relative "provider/slack/slack_provider.rb"
require_relative "provider/telegram/telegram_provider.rb"