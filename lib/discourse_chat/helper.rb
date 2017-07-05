module DiscourseChat
  module Helper
	
  	def self.status_for_channel(provider, channel)
  		rules = DiscourseChat::Rule.all_for_channel(provider, channel)

  		text = I18n.t("chat_integration.provider.#{provider}.status.header") + "\n"

  		i = 1
  		rules.each do |rule|
        category_id = rule.category_id
        if category_id.nil?
          category_name = I18n.t("chat_integration.all_categories")
        else
          category = Category.find_by(id: category_id)
          if category
            category_name = category.slug
          else
            category_name = I18n.t("chat_integration.deleted_category")
          end
        end

        text << I18n.t("chat_integration.provider.#{provider}.status.rule_string",
                          index: i,
                          filter: rule.filter,
                          category: category_name
                      )

        if SiteSetting.tagging_enabled and not rule.tags.nil?
          text << I18n.t("chat_integration.provider.#{provider}.status.rule_string_tags_suffix", tags: rule.tags.join(', '))
        end

        text << "\n"
  			i += 1
  		end

      if rules.size == 0
        text << I18n.t("chat_integration.provider.#{provider}.status.no_rules")
      end
      return text
  	end

  end
end

