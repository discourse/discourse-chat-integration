class DiscourseChat::RuleSerializer < ActiveModel::Serializer
  attributes :id, :provider, :channel, :category_id, :tags, :filter, :error_key
end