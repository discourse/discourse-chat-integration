module ::DiscourseChat
  PLUGIN_NAME = "discourse-chat-integration".freeze

  class AdminEngine < ::Rails::Engine
    engine_name DiscourseChat::PLUGIN_NAME+"-admin"
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