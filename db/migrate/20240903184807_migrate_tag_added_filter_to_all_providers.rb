# frozen_string_literal: true
class MigrateTagAddedFilterToAllProviders < ActiveRecord::Migration[7.1]
  def up
    if defined?(DiscourseAutomation)
      begin
        slack_usage_rows = DB.query <<~SQL
        SELECT plugin_store_rows.* FROM plugin_store_rows
        WHERE plugin_store_rows.type_name = 'JSON'
        AND plugin_store_rows.plugin_name = 'discourse-chat-integration'
        AND (key LIKE 'channel:%')
        AND (value::json->>'provider'='slack')
        SQL

        old_migration_delete = <<~SQL
        DELETE FROM discourse_automation_automations
        WHERE id IN (
          SELECT a.id
          FROM discourse_automation_automations a
          JOIN discourse_automation_fields f ON f.automation_id = a.id
          WHERE a.script = 'send_slack_message'
            AND a.trigger = 'topic_tags_changed'
            AND a.name = 'When tags change in topic'
            AND f.name = 'message'
            AND f.metadata->>'value' = '${ADDED_AND_REMOVED}'
        )
        SQL
        # Trash old migration
        DB.exec old_migration_delete if slack_usage_rows.count > 0

        rules_with_tag_added = <<~SQL
        SELECT value
        FROM plugin_store_rows
        WHERE plugin_name = 'discourse-chat-integration'
          AND key LIKE 'rule:%'
          AND value::json->>'filter' = 'tag_added'
        SQL

        channel_query = <<~SQL
        SELECT *
        FROM plugin_store_rows
        WHERE type_name = 'JSON'
          AND plugin_name = 'discourse-chat-integration'
          AND key LIKE 'channel:%'
          AND id = :channel_id
        LIMIT 1
        SQL

        DB
          .query(rules_with_tag_added)
          .each do |row|
            rule = JSON.parse(row.value).with_indifferent_access

            channel =
              JSON.parse(
                DB.query(channel_query, channel_id: rule[:channel_id]).first.value,
              ).with_indifferent_access

            provider_name = channel[:provider]
            provider = DiscourseChatIntegration::Provider.get_by_name(provider_name)
            channel_name = provider.get_channel_name(channel)
            category_id = rule[:category_id]
            tags = rule[:tags]

            automation_creation = <<~SQL
            WITH new_automation AS (
              INSERT INTO discourse_automation_automations
              (script, trigger, name, enabled, last_updated_by_id, created_at, updated_at)
              VALUES
              ('send_chat_integration_message', 'topic_tags_changed', 'When tags change in topic', true,
              (SELECT id FROM users WHERE admin = true ORDER BY id ASC LIMIT 1), -- assuming this gets the system user
              NOW(), NOW())
              RETURNING id
            )
            -- Insert watching_categories field
            INSERT INTO discourse_automation_fields
            (automation_id, name, type, metadata, target, created_at, updated_at)
            SELECT
              new_automation.id,
              'watching_categories',
              'categories',
              CASE
                WHEN :category_id IS NOT NULL THEN jsonb_build_object('value', jsonb_build_array(:category_id))
                ELSE '{}'::jsonb
              END,
              'trigger',
              NOW(),
              NOW()
            FROM new_automation
            WHERE :category_id IS NOT NULL;

            -- Insert watching_tags field
            INSERT INTO discourse_automation_fields
            (automation_id, name, type, metadata, target, created_at, updated_at)
            SELECT
              new_automation.id,
              'watching_tags',
              'tags',
              CASE
                WHEN :tags IS NOT NULL AND :tags <> '{}' THEN jsonb_build_object('value', :tags::jsonb)
                ELSE '{}'::jsonb
              END,
              'trigger',
              NOW(),
              NOW()
            FROM new_automation
            WHERE :tags IS NOT NULL AND :tags <> '{}';

            -- Insert provider field
            INSERT INTO discourse_automation_fields
            (automation_id, name, type, metadata, target, created_at, updated_at)
            SELECT
              new_automation.id,
              'provider',
              'choices',
              jsonb_build_object('value', :provider_name),
              'script',
              NOW(),
              NOW()
            FROM new_automation;

            -- Insert channel_name field
            INSERT INTO discourse_automation_fields
            (automation_id, name, type, metadata, target, created_at, updated_at)
            SELECT
              new_automation.id,
              'channel_name',
              'text',
              jsonb_build_object('value', :channel_name),
              'script',
              NOW(),
              NOW()
            FROM new_automation;
            SQL

            DB.exec(
              automation_creation,
              category_id: category_id,
              tags: tags,
              provider_name: provider_name,
              channel_name: channel_name,
            )
          end
      rescue StandardError
        puts "Error migrating tag_added filters to all providers"
      end
    end
  end

  def down
    DB.exec <<~SQL if defined?(DiscourseAutomation)
        DELETE FROM discourse_automation_automations
        WHERE script = 'send_chat_integration_message'
          AND trigger = 'topic_tags_changed'
          AND name = 'When tags change in topic'
      SQL
  end
end
