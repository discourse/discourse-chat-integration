class DiscourseChat::Rule < PluginStoreRow
  PLUGIN_NAME = 'discourse-chat-integration'
  KEY_PREFIX = 'rule:'
  
  # Restrict the scope to JSON PluginStoreRows which are for this plugin, and this model
  default_scope { where(type_name: 'JSON')
                  .where(plugin_name: PLUGIN_NAME)
                  .where("key like?", "#{KEY_PREFIX}%") 
                }

  # Setup ActiveRecord::Store to use the JSON field to read/write these values
  store :value, accessors: [ :provider, :channel, :category_id, :tags, :filter, :error_key ], coder: JSON

  before_save :set_key

  after_initialize :init

  def init
    self.filter  ||= 'watch'
  end

  validates :filter, :inclusion => { :in => %w(watch follow mute),
    :message => "%{value} is not a valid filter" }

  validate :provider_and_channel_valid?, :category_valid?, :tags_valid?

  def provider_and_channel_valid?
    # Validate provider
    if not ::DiscourseChat::Provider.provider_names.include? provider
      errors.add(:provider, "#{provider} is not a valid provider")
      return
    end
    
    # Validate channel
    if channel.blank? 
      errors.add(:channel, "channel cannot be blank")
      return
    end

    provider_class = ::DiscourseChat::Provider.get_by_name(provider)
    if defined? provider_class::PROVIDER_CHANNEL_REGEX
      channel_regex = Regexp.new provider_class::PROVIDER_CHANNEL_REGEX
      if not channel_regex.match?(channel)
        errors.add(:channel, "#{channel} is not a valid channel for provider #{provider}")
      end
    end
  end

  def category_valid?
    # Validate category
    if not (category_id.nil? or Category.where(id: category_id).exists?)
      errors.add(:category_id, "#{category_id} is not a valid category id")
    end
  end

  def tags_valid?
    # Validate tags
    return if tags.nil?
    tags.each do |tag|
      if not Tag.where(name: tag).exists?
        errors.add(:tags, "#{tag} is not a valid tag")
      end
    end
  end

  # We never want an empty array, set it to nil instead
  def tags=(array)
    if array.nil? or array.empty?
      super(nil)
    else
      super(array)
    end
  end

  # Don't want this to end up as anything other than an integer
  def category_id=(val)
    if val.nil? or val.blank?
      super(nil)
    else
      super(val.to_i)
    end
  end

  scope :with_provider, ->(provider) { where("value::json->>'provider'=?", provider)} 

  scope :with_channel, ->(provider, channel) { with_provider(provider).where("value::json->>'channel'=?", channel)} 

  scope :with_category, ->(category_id) { category_id.nil? ? where("(value::json->'category_id') IS NULL OR json_typeof(value::json->'category_id')='null'") : where("value::json->>'category_id'=?", category_id.to_s)}

  private

    def set_key
      self.key ||= alloc_key
    end

    def alloc_key
      DistributedMutex.synchronize("#{PLUGIN_NAME}_#{KEY_PREFIX}_id") do
        max_id = PluginStore.get(PLUGIN_NAME, "#{KEY_PREFIX}_id")
        max_id = 1 unless max_id
        PluginStore.set(PLUGIN_NAME, "#{KEY_PREFIX}_id", max_id + 1)
        "#{KEY_PREFIX}#{max_id}"
      end
    end

end