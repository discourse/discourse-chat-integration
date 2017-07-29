class DiscourseChat::Channel < DiscourseChat::PluginModel
  KEY_PREFIX = 'channel:'

  # Setup ActiveRecord::Store to use the JSON field to read/write these values
  store :value, accessors: [ :provider, :error_key, :data ], coder: JSON

  after_initialize :init_data

  def init_data
    self.data = {} if self.data.nil?
  end

  after_destroy :destroy_rules
  def destroy_rules
    rules.destroy_all()
  end

  validate :provider_valid?, :data_valid?

  def provider_valid?
    # Validate provider
    if not ::DiscourseChat::Provider.provider_names.include? provider
      errors.add(:provider, "#{provider} is not a valid provider")
      return
    end
  end

  def data_valid?
    # If provider is invalid, don't try and check data
    return unless ::DiscourseChat::Provider.provider_names.include? provider

    params = ::DiscourseChat::Provider.get_by_name(provider)::CHANNEL_PARAMETERS

    unless params.map {|p| p[:key]}.sort == data.keys.sort
      errors.add(:data, "data does not match the required structure for provider #{provider}")
      return
    end

    check_unique = false
    matching_channels = DiscourseChat::Channel.all

    data.each do |key, value|
      regex_string = params.find{|p| p[:key] == key}[:regex]
      if !Regexp.new(regex_string).match(value)
        errors.add(:data, "data.#{key} is invalid")
      end

      unique = params.find{|p| p[:key] == key}[:unique]
      if unique
        check_unique = true
        matching_channels = matching_channels.with_data_value(key, value)
      end
    end
    
    if check_unique && matching_channels.exists?
      errors.add(:data, "matches an existing channel")
    end

  end

  def rules
    DiscourseChat::Rule.with_channel_id(id)
  end

  scope :with_provider, ->(provider) { where("value::json->>'provider'=?", provider)} 

  scope :with_data_value, ->(key, value) { where("(value::json->>'data')::json->>?=?", key.to_s, value.to_s)} 

end