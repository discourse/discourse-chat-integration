# frozen_string_literal: true

class DiscourseChat::Channel < DiscourseChat::PluginModel
  # Setup ActiveRecord::Store to use the JSON field to read/write these values
  store :value, accessors: [ :provider, :error_key, :error_info, :data ], coder: JSON

  scope :with_provider, ->(provider) { where("JSON_EXTRACT(CAST(value AS JSON), '$.provider')=?", provider) }
  scope :with_data_value, ->(key, value) { where("JSON_EXTRACT(CAST(value AS JSON), '$.#{key.to_s}')=?", value.to_s) }

  after_initialize :init_data
  after_destroy :destroy_rules

  validate :provider_valid?, :data_valid?

  def self.key_prefix
    'channel:'.freeze
  end

  def rules
    DiscourseChat::Rule.with_channel_id(id).order_by_precedence
  end

  private

  def init_data
    self.data = {} if self.data.nil?
  end

  def destroy_rules
    rules.destroy_all
  end

  def provider_valid?
    if !DiscourseChat::Provider.provider_names.include?(provider)
      errors.add(:provider, "#{provider} is not a valid provider")
    end
  end

  def data_valid?
    # If provider is invalid, don't try and check data
    return unless ::DiscourseChat::Provider.provider_names.include? provider

    params = ::DiscourseChat::Provider.get_by_name(provider)::CHANNEL_PARAMETERS

    unless params.map { |p| p[:key] }.sort == data.keys.sort
      errors.add(:data, "data does not match the required structure for provider #{provider}")
      return
    end

    check_unique = false
    matching_channels = DiscourseChat::Channel.with_provider(provider).where.not(id: id)

    data.each do |key, value|
      regex_string = params.find { |p| p[:key] == key }[:regex]
      if !Regexp.new(regex_string).match(value)
        errors.add(:data, "data.#{key} is invalid")
      end

      unique = params.find { |p| p[:key] == key }[:unique]
      if unique
        check_unique = true
        matching_channels = matching_channels.with_data_value(key, value)
      end
    end

    if check_unique && matching_channels.exists?
      errors.add(:data, "matches an existing channel")
    end
  end
end
