class DiscourseChat::RuleSerializer < ApplicationSerializer
  attributes :id, :channel_id, :category_id, :tags, :filter
end