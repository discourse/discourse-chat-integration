# frozen_string_literal: true

class DiscourseChat::Rule < DiscourseChat::PluginModel
  # Setup ActiveRecord::Store to use the JSON field to read/write these values
  store :value, accessors: [ :channel_id, :type, :group_id, :category_id, :tags, :filter ], coder: JSON

  scope :with_type, ->(type) { where("JSON_EXTRACT(CAST(value AS JSON), '$.type')=?", type.to_s) }
  scope :with_channel, ->(channel) { with_channel_id(channel.id) }
  scope :with_channel_id, ->(channel_id) { where("JSON_EXTRACT(CAST(value AS JSON), '$.channel_id')=?", channel_id.to_s) }

  scope :with_category_id, ->(category_id) do
    if category_id.nil?
      where("JSON_EXTRACT(CAST(value AS JSON), '$.category_id') IS NULL OR JSON_EXTRACT(CAST(value AS JSON), '$.category_id')='null'")
    else
      where("JSON_EXTRACT(CAST(value AS JSON), '$.category_id')=?", category_id.to_s)
    end
  end

  scope :with_group_ids, ->(group_id) do
    where("JSON_EXTRACT(CAST(value AS JSON), '$.group_id') IN (?)", group_id.map!(&:to_s))
  end

  scope :order_by_precedence, -> {
    order("
      CASE
      WHEN JSON_EXTRACT(CAST(value AS JSON), '$.type') = 'group_mention' THEN 1
      WHEN JSON_EXTRACT(CAST(value AS JSON), '$.type') = 'group_message' THEN 2
      ELSE 3
      END
    ",
    "
      CASE
      WHEN JSON_EXTRACT(CAST(value AS JSON), '$.filter') = 'mute' THEN 1
      WHEN JSON_EXTRACT(CAST(value AS JSON), '$.filter') = 'watch' THEN 2
      WHEN JSON_EXTRACT(CAST(value AS JSON), '$.filter') = 'follow' THEN 3
     END
    ")
  }

  after_initialize :init_filter

  validates :filter, inclusion: { in: %w(watch follow mute),
                                  message: "%{value} is not a valid filter" }

  validates :type, inclusion: { in: %w(normal group_message group_mention),
                                message: "%{value} is not a valid filter" }

  validate :channel_valid?, :category_valid?, :group_valid?, :tags_valid?

  def self.key_prefix
    'rule:'.freeze
  end

  # We never want an empty array, set it to nil instead
  def tags=(array)
    if array.nil? || array.empty?
      super(nil)
    else
      super(array)
    end
  end

  # These are only allowed to be integers
  %w(channel_id category_id group_id).each do |name|
    define_method "#{name}=" do |val|
      if val.nil? || val.blank?
        super(nil)
      else
        super(val.to_i)
      end
    end
  end

  # Mock foreign key
  # Could return nil
  def channel
    DiscourseChat::Channel.find_by(id: channel_id)
  end

  def channel=(val)
    self.channel_id = val.id
  end

  private

  def channel_valid?
    if !(DiscourseChat::Channel.where(id: channel_id).exists?)
      errors.add(:channel_id, "#{channel_id} is not a valid channel id")
    end
  end

  def category_valid?
    if type != 'normal' && !category_id.nil?
      errors.add(:category_id, "cannot be specified for that type of rule")
    end

    return unless type == 'normal'

    if !(category_id.nil? || Category.where(id: category_id).exists?)
      errors.add(:category_id, "#{category_id} is not a valid category id")
    end
  end

  def group_valid?
    if type == 'normal' && !group_id.nil?
      errors.add(:group_id, "cannot be specified for that type of rule")
    end

    return if type == 'normal'

    if !Group.where(id: group_id).exists?
      errors.add(:group_id, "#{group_id} is not a valid group id")
    end
  end

  def tags_valid?
    return if tags.nil?

    tags.each do |tag|
      if !Tag.where(name: tag).exists?
        errors.add(:tags, "#{tag} is not a valid tag")
      end
    end
  end

  def init_filter
    self.filter ||= 'watch'
    self.type ||= 'normal'
  end
end
