module Jobs
  class DiscourseChatMigrateFromSlackOfficial < Jobs::Onceoff
    def execute_onceoff(args)
      # Check if slack plugin is installed by testing if the sitesetting exists
      slack_installed = defined? DiscourseSlack

      already_setup_rules = DiscourseChat::Channel.with_provider('slack').exists?

      already_setup_sitesettings =
        SiteSetting.chat_integration_slack_enabled ||
        !SiteSetting.chat_integration_slack_access_token.blank? ||
        !SiteSetting.chat_integration_slack_incoming_webhook_token.blank? ||
        !SiteSetting.chat_integration_slack_outbound_webhook_url.blank?

      if !already_setup_rules && !already_setup_sitesettings
        migrate_settings()
        migrate_data()
      end

    end

    def migrate_data
      in_console = Rails.const_defined? 'Console'

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

          rows << {
            category_id: category_id,
            channel: rule[:channel],
            filter: rule[:filter],
            tags: rule[:tags]
          }
        end
      end

      rows.each do |row|
        # Load an existing channel with this identifier. If none, create it
        channel = DiscourseChat::Channel.with_provider('slack').with_data_value('identifier', row[:channel]).first
        if !channel
          channel = DiscourseChat::Channel.create(provider: 'slack', data: { identifier: row[:channel] })
          if !channel.id
            puts "Error creating channel for #{row}" if in_console
            next
          end
        end

        # Create the rule, with clever logic for avoiding duplicates
        success = DiscourseChat::Helper.smart_create_rule(channel: channel, filter: row[:filter], category_id: row[:category_id], tags: row[:tags])

        if in_console
          puts (success ? "Success creating #{row}" : "Error creating #{row}")
        end
      end

    end

    def migrate_settings
      in_console = Rails.const_defined? 'Console'

      SiteSetting.chat_integration_slack_access_token = SiteSetting.slack_access_token
      SiteSetting.chat_integration_slack_incoming_webhook_token = SiteSetting.slack_incoming_webhook_token
      SiteSetting.chat_integration_slack_excerpt_length = SiteSetting.slack_discourse_excerpt_length
      SiteSetting.chat_integration_slack_outbound_webhook_url = SiteSetting.slack_outbound_webhook_url
      SiteSetting.chat_integration_slack_icon_url = SiteSetting.slack_icon_url
      SiteSetting.chat_integration_delay_seconds = SiteSetting.post_to_slack_window_secs
      SiteSetting.chat_integration_discourse_username = SiteSetting.slack_discourse_username

      puts "Site Settings migrated" if in_console
    end

  end
end
