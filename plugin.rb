# name: discourse-chat
# about: This plugin integrates discourse with a number of chat providers
# version: 0.1
# url: https://github.com/discourse/discourse-chat

enabled_site_setting :discourse_chat_enabled

after_initialize do

  module ::DiscourseChat
    PLUGIN_NAME = "discourse-chat".freeze

    class Engine < ::Rails::Engine
      engine_name DiscourseChat::PLUGIN_NAME
      isolate_namespace DiscourseChat
    end
  end
end
