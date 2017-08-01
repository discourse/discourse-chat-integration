module ::DiscourseChat
  PLUGIN_NAME = "discourse-chat-integration".freeze

  class AdminEngine < ::Rails::Engine
    engine_name DiscourseChat::PLUGIN_NAME + "-admin"
    isolate_namespace DiscourseChat
  end

  class PublicEngine < ::Rails::Engine
    engine_name DiscourseChat::PLUGIN_NAME + "-public"
    isolate_namespace DiscourseChat
  end

  def self.plugin_name
    DiscourseChat::PLUGIN_NAME
  end

  def self.pstore_get(key)
    PluginStore.get(self.plugin_name, key)
  end

  def self.pstore_set(key, value)
    PluginStore.set(self.plugin_name, key, value)
  end

  def self.pstore_delete(key)
    PluginStore.remove(self.plugin_name, key)
  end
end

require_relative "../models/plugin_model"
require_relative "../models/rule"
require_relative "../models/channel"

require_relative "../serializers/channel_serializer"
require_relative "../serializers/rule_serializer"

require_relative "../controllers/chat_controller"
require_relative "../controllers/public_controller"

require_relative "../routes/discourse_chat"
require_relative "../routes/discourse"

require_relative "../helpers/helper"

require_relative "../services/manager"

require_relative "../jobs/regular/notify_chats"

require_relative "../../lib/discourse_chat/provider"

require_relative "../jobs/onceoff/add_type_field"
