# frozen_string_literal: true
class MigrateTagAddedFilterToAllProviders < ActiveRecord::Migration[7.1]
  def up
    if defined?(DiscourseAutomation)
      begin
        DiscourseChatIntegration::Rule
          .where("value::json->>'filter'=?", "tag_added")
          .each do |rule|
            channel_id = rule.channel_id
            channel = DiscourseChatIntegration::Channel.find(channel_id)
            # channel names are unique but built from the provider
            provider_name = channel.provider
            provider = DiscourseChatIntegration::Provider.get_by_name(provider_name)
            channel_name = provider.get_channel_name(channel)

            category_id = rule.category_id
            tags = rule.tags

            automation =
              DiscourseAutomation::Automation.new(
                script: "send_chat_integration_message",
                trigger: "topic_tags_changed",
                name: "When tags change in topic",
                enabled: true,
                last_updated_by_id: Discourse.system_user.id,
              )

            automation.save!

            # Triggers:
            # Watching categories

            metadata = (category_id ? { "value" => [category_id] } : {})

            automation.upsert_field!(
              "watching_categories",
              "categories",
              metadata,
              target: "trigger",
            )

            # Watching tags

            metadata = (tags ? { "value" => tags } : {})
            automation.upsert_field!("watching_tags", "tags", metadata, target: "trigger")

            # Script options:
            # Provider
            automation.upsert_field!(
              "provider",
              "choices",
              { "value" => provider_name },
              target: "script",
            )

            # Channel name
            automation.upsert_field!(
              "channel_name",
              "text",
              { "value" => channel_name },
              target: "script",
            )
          end
      rescue StandardError
        Rails.logger.warn("Failed to migrate tag_added rule to all providers automations")
      end
    end
  end
  def down
    if defined?(DiscourseAutomation)
      DiscourseAutomation::Automation
        .where(script: "send_chat_integration_message")
        .where(trigger: "topic_tags_changed")
        .where(name: "When tags change in topic")
        .destroy_all
    end
  end
end
