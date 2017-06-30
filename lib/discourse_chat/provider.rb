module DiscourseChat
  module Provider
    def self.providers
      constants.select do |constant|
        constant.to_s =~ /Provider$/
      end.map(&method(:const_get))
    end

    def self.get_by_name(name)
      self.providers.find{|p| p::PROVIDER_NAME == name}
    end

  end
end

require_relative "provider/slack/slack_provider.rb"
require_relative "provider/telegram/telegram_provider.rb"