# frozen_string_literal: true

# name: discourse-chat-integration
# about: Allows integration with several external chat system providers
# meta_topic_id: 66522
# version: 0.1
# url: https://github.com/discourse/discourse-chat-integration
# author: David Taylor

enabled_site_setting :chat_integration_enabled

register_asset "stylesheets/chat-integration.scss"

register_svg_icon "rocket" if respond_to?(:register_svg_icon)
register_svg_icon "fa-arrow-circle-o-right" if respond_to?(:register_svg_icon)

# Site setting validators must be loaded before initialize
require_relative "lib/discourse_chat_integration/provider/slack/slack_enabled_setting_validator"

after_initialize do
  require_relative "app/initializers/discourse_chat_integration"

  require_relative "app/services/problem_check/channel_errors"

  register_problem_check ProblemCheck::ChannelErrors

  on(:site_setting_changed) do |setting_name, old_value, new_value|
    is_enabled_setting = setting_name == :chat_integration_telegram_enabled
    is_access_token = setting_name == :chat_integration_telegram_access_token

    if (is_enabled_setting || is_access_token)
      enabled =
        is_enabled_setting ? new_value == true : SiteSetting.chat_integration_telegram_enabled

      if enabled && SiteSetting.chat_integration_telegram_access_token.present?
        Scheduler::Defer.later("Setup Telegram Webhook") do
          DiscourseChatIntegration::Provider::TelegramProvider.setup_webhook
        end
      end
    end
  end

  on(:post_created) do |post|
    # This will run for every post, even PMs. Don't worry, they're filtered out later.
    time = SiteSetting.chat_integration_delay_seconds.seconds
    Jobs.enqueue_in(time, :notify_chats, post_id: post.id)
  end

  add_admin_route "chat_integration.menu_title", "chat-integration"

  DiscourseChatIntegration::Provider.mount_engines

  if defined?(DiscourseAutomation)
    add_automation_scriptable("send_slack_message") do
      field :message, component: :message, required: true, accepts_placeholders: true
      field :url, component: :text, required: true
      field :channel, component: :text, required: true

      version 1

      triggerables %i[point_in_time recurring topic_tags_changed]

      script do |context, fields, automation|
        channel_name = fields.dig("channel", "value")
        channel =
          DiscourseChatIntegration::Channel.new(
            provider: "slack",
            data: {
              identifier: "##{channel_name}",
            },
          )

        message, should_send =
          DiscourseChatIntegration::Provider::SlackProvider.create_slack_message(
            context: context,
            content: fields.dig("message", "value"),
            url: fields.dig("url", "value"),
            channel_name: channel_name,
          )
        if should_send
          DiscourseChatIntegration::Provider::SlackProvider.send_via_api(nil, channel, message)
        end
      end
    end
  end
end
