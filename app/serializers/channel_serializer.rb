require_relative './rule_serializer'

class DiscourseChat::ChannelSerializer < ApplicationSerializer
  attributes :id, :provider, :data, :rules

  def rules
    object.rules.map do |rule|
      DiscourseChat::RuleSerializer.new(rule, root:false)
    end
  end
end