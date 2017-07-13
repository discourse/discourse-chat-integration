class DiscourseChat::Channel < DiscourseChat::PluginModel
  KEY_PREFIX = 'channel:'

  # Setup ActiveRecord::Store to use the JSON field to read/write these values
  store :value, accessors: [ :provider, :descriptor ], coder: JSON

  validate :provider_and_descriptor_valid?

  def provider_and_descriptor_valid?
    # Validate provider
    if not ::DiscourseChat::Provider.provider_names.include? provider
      errors.add(:provider, "#{provider} is not a valid provider")
      return
    end
    
    # Validate descriptor
    if descriptor.blank? 
      errors.add(:descriptor, "channel descriptor cannot be blank")
      return
    end

    provider_class = ::DiscourseChat::Provider.get_by_name(provider)
    if defined? provider_class::PROVIDER_CHANNEL_REGEX
      channel_regex = Regexp.new provider_class::PROVIDER_CHANNEL_REGEX
      if not channel_regex.match?(descriptor)
        errors.add(:descriptor, "#{descriptor} is not a valid channel descriptor for provider #{provider}")
      end
    end
  end

  def rules
    DiscourseChat::Rule.with_channel_id(id)
  end

  scope :with_provider, ->(provider) { where("value::json->>'provider'=?", provider)} 

end