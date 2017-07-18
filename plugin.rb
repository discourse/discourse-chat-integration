# name: discourse-chat-integration
# about: This plugin integrates discourse with a number of chat providers
# version: 0.1
# url: https://github.com/discourse/discourse-chat-integration
# author: David Taylor

enabled_site_setting :chat_integration_enabled

register_asset "stylesheets/chat-integration-admin.scss"

# Site setting validators must be loaded before initialize
require_relative "lib/discourse_chat/provider/slack/slack_enabled_setting_validator"

after_initialize do

  require_relative "app/initializers/discourse_chat"

  require_relative "app/models/plugin_model"
  require_relative "app/models/rule"
  require_relative "app/models/channel"

  require_relative "app/serializers/channel_serializer"
  require_relative "app/serializers/rule_serializer"
  
  require_relative "app/controllers/chat_controller"

  require_relative "app/routes/discourse_chat"
  require_relative "app/routes/discourse"

  require_relative "app/helpers/helper"
  
  require_relative "app/services/manager"

  require_relative "app/jobs/regular/notify_chats"

  require_relative "lib/discourse_chat/provider"
  
  DiscourseEvent.on(:post_created) do |post| 
    if SiteSetting.chat_integration_enabled?
      # This will run for every post, even PMs. Don't worry, they're filtered out later.
      time = SiteSetting.chat_integration_delay_seconds.seconds
      Jobs.enqueue_in(time, :notify_chats, post_id: post.id)
    end
  end

  add_admin_route 'chat_integration.menu_title', 'chat'

  DiscourseChat::Provider.mount_engines

end
