module Jobs
  class DiscourseChatMigrateFromSlackOfficial < Jobs::Onceoff
    def execute_onceoff(args)
      slack_installed = PluginStoreRow.where(plugin_name: 'discourse-slack-official').exists?

      if slack_installed
        already_setup_rules = DiscourseChat::Channel.with_provider('slack').exists?

        already_setup_sitesettings =
          SiteSetting.chat_integration_slack_enabled ||
          SiteSetting.chat_integration_slack_access_token.present? ||
          SiteSetting.chat_integration_slack_incoming_webhook_token.present? ||
          SiteSetting.chat_integration_slack_outbound_webhook_url.present?

        if !already_setup_rules && !already_setup_sitesettings
          ActiveRecord::Base.transaction do
            migrate_settings
            migrate_data
            is_slack_enabled = SiteSetting.slack_enabled

            if is_slack_enabled
              SiteSetting.slack_enabled = false
              SiteSetting.chat_integration_slack_enabled = true
              SiteSetting.chat_integration_enabled = true
            end
          end
        end
      end

    end

    def migrate_data
      rows = []
      PluginStoreRow.where(plugin_name: 'discourse-slack-official')
        .where("key ~* :pat", pat: "^category_.*")
        .each do |row|

        PluginStore.cast_value(row.type_name, row.value).each do |rule|
          category_id =
            if row.key == 'category_*'
              nil
            else
              row.key.gsub!('category_', '')
              row.key.to_i
            end

          next if !category_id.nil? && !Category.exists?(id: category_id)

          valid_tags = []
          valid_tags = Tag.where(name: rule[:tags]).pluck(:name) if rule[:tags]

          rows << {
            category_id: category_id,
            channel: rule[:channel],
            filter: rule[:filter],
            tags: valid_tags
          }
        end
      end

      rows.each do |row|
        # Load an existing channel with this identifier. If none, create it
        channel = DiscourseChat::Channel.with_provider('slack').with_data_value('identifier', row[:channel]).first
        if !channel
          channel = DiscourseChat::Channel.create(provider: 'slack', data: { identifier: row[:channel] })
          if !channel.id
            Rails.logger.warn("Error creating channel for #{row}")
            next
          end
        end

        # Create the rule, with clever logic for avoiding duplicates
        success = DiscourseChat::Helper.smart_create_rule(channel: channel, filter: row[:filter], category_id: row[:category_id], tags: row[:tags])
      end

    end

    def migrate_settings
      SiteSetting.chat_integration_slack_access_token = SiteSetting.slack_access_token
      SiteSetting.chat_integration_slack_incoming_webhook_token = SiteSetting.slack_incoming_webhook_token
      SiteSetting.chat_integration_slack_excerpt_length = SiteSetting.slack_discourse_excerpt_length
      SiteSetting.chat_integration_slack_outbound_webhook_url = SiteSetting.slack_outbound_webhook_url
      SiteSetting.chat_integration_slack_icon_url = SiteSetting.slack_icon_url
      SiteSetting.chat_integration_delay_seconds = SiteSetting.post_to_slack_window_secs
      SiteSetting.chat_integration_discourse_username = SiteSetting.slack_discourse_username
    end

  end
end
