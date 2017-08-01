class DiscourseChat::RuleSerializer < ApplicationSerializer
  attributes :id, :channel_id, :type, :group_id, :group_name, :category_id, :tags, :filter

  def group_name
    if object.group_id
      groups = Group.where(id: object.group_id)
      if groups.exists?
        return groups.first.name
      else
        return I18n.t("chat_integration.deleted_group")
      end
    end
  end
end
