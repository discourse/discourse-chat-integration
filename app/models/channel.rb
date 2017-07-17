class DiscourseChat::Channel < DiscourseChat::PluginModel
  KEY_PREFIX = 'channel:'

  # Setup ActiveRecord::Store to use the JSON field to read/write these values
  store :value, accessors: [ :name ], coder: JSON

end