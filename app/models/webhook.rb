# frozen_string_literal: true

class DiscourseChat::Webhook < DiscourseChat::PluginModel
  # Setup ActiveRecord::Store to use the JSON field to read/write these values
  store :value, accessors: [ :provider, :data ], coder: JSON

  scope :with_provider, ->(provider) { where("value::json->>'provider'=?", provider) }
  scope :with_data_value, ->(key, value) { where("(value::json->>'data')::json->>?=?", key.to_s, value.to_s) }

  after_initialize :init_data

  validate :provider_valid?, :data_valid?

  def self.key_prefix
    'webhook:'.freeze
  end

  private

  def init_data
    self.data = {} if self.data.nil?
  end

  def provider_valid?
    if !DiscourseChat::Provider.provider_names.include?(provider)
      errors.add(:provider, "#{provider} is not a valid provider")
    end
  end

  def data_valid?
    # If provider is invalid, don't try and check data
    return unless ::DiscourseChat::Provider.provider_names.include? provider

    params = ::DiscourseChat::Provider.get_by_name(provider)::WEBHOOK_PARAMETERS

    unless params.map { |p| p[:key] }.sort == data.keys.sort
      errors.add(:data, "data does not match the required structure for provider #{provider}")
      return
    end

    check_unique = false
    matching_webhooks = DiscourseChat::Webhook.with_provider(provider).where.not(id: id)

    data.each do |key, value|
      regex_string = params.find { |p| p[:key] == key }[:regex]
      if !Regexp.new(regex_string).match(value)
        errors.add(:data, "data.#{key} is invalid")
      end

      unique = params.find { |p| p[:key] == key }[:unique]
      if unique
        check_unique = true
        matching_webhooks = matching_webhooks.with_data_value(key, value)
      end
    end

    if check_unique && matching_webhooks.exists?
      errors.add(:data, "matches an existing webhook")
    end
  end
end
