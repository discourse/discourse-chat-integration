module DiscourseChat
	module Integration
		def self.integrations
	      constants.select do |constant|
	        constant.to_s =~ /Integration$/
	      end.map(&method(:const_get))
	    end
	end
end

require_relative "integration/slack/slack_integration.rb"
require_relative "integration/telegram/telegram_integration.rb"