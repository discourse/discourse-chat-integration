class DiscourseChat::PluginModel < PluginStoreRow
  PLUGIN_NAME = 'discourse-chat-integration'
  KEY_PREFIX = 'unimplemented'

  after_initialize :init_plugin_model
  default_scope { self.default_scope }

  def init_plugin_model
    self.type_name ||= 'JSON'
    self.plugin_name ||= PLUGIN_NAME
  end

  # Restrict the scope to JSON PluginStoreRows which are for this plugin, and this model
  def self.default_scope
    where(type_name: 'JSON')
      .where(plugin_name: self::PLUGIN_NAME)
      .where("key LIKE ?", "#{self::KEY_PREFIX}%")
  end

  before_save :set_key

  private

    def set_key
      self.key ||= self.class.alloc_key
    end

    def self.alloc_key
      raise "KEY_PREFIX must be defined" if self::KEY_PREFIX == 'unimplemented'
      DistributedMutex.synchronize("#{self::PLUGIN_NAME}_#{self::KEY_PREFIX}_id") do
        max_id = PluginStore.get(self::PLUGIN_NAME, "#{self::KEY_PREFIX}_id")
        max_id = 1 unless max_id
        PluginStore.set(self::PLUGIN_NAME, "#{self::KEY_PREFIX}_id", max_id + 1)
        "#{self::KEY_PREFIX}#{max_id}"
      end
    end

end
