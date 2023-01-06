# frozen_string_literal: true

# name: discourse-chat-integration
# about: This plugin integrates discourse with a number of chat providers
# version: 0.1
# url: https://github.com/discourse/discourse-chat-integration
# author: David Taylor
# transpile_js: true

enabled_site_setting :chat_integration_enabled

register_asset "stylesheets/chat-integration-admin.scss"

register_svg_icon "rocket" if respond_to?(:register_svg_icon)
register_svg_icon "fa-arrow-circle-o-right" if respond_to?(:register_svg_icon)

# Site setting validators must be loaded before initialize
require_relative "lib/discourse_chat_integration/provider/slack/slack_enabled_setting_validator"

after_initialize do
  require_relative "app/initializers/discourse_chat_integration"

  on(:post_created) do |post|
    # This will run for every post, even PMs. Don't worry, they're filtered out later.
    time = SiteSetting.chat_integration_delay_seconds.seconds
    Jobs.enqueue_in(time, :notify_chats, post_id: post.id)
  end

  add_admin_route "chat_integration.menu_title", "chat-integration"

  AdminDashboardData.add_problem_check do
    next if !SiteSetting.chat_integration_enabled

    error = false
    DiscourseChatIntegration::Channel.find_each do |channel|
      next if channel.error_key.blank?
      next if !::DiscourseChatIntegration::Provider.is_enabled(channel.provider)
      error = true
    end

    if error
      base_path = Discourse.respond_to?(:base_path) ? Discourse.base_path : Discourse.base_uri
      I18n.t("chat_integration.admin_error", base_path: base_path)
    end
  end

  DiscourseChatIntegration::Provider.mount_engines

  if defined?(DiscourseAutomation)
    add_automation_scriptable("send_slack_message") do
      field :message, component: :message, required: true, accepts_placeholders: true
      field :url, component: :text, required: true
      field :channel, component: :text, required: true

      version 1

      triggerables %i[point_in_time recurring]

      script do |context, fields, automation|
        sender = Discourse.system_user

        content = fields.dig("message", "value")
        url = fields.dig("url", "value")
        full_content = "#{content} - #{url}"
        channel_name = fields.dig("channel", "value")
        channel =
          DiscourseChatIntegration::Channel.new(
            provider: "slack",
            data: {
              identifier: "##{channel_name}",
            },
          )

        icon_url =
          if SiteSetting.chat_integration_slack_icon_url.present?
            "#{Discourse.base_url}#{SiteSetting.chat_integration_slack_icon_url}"
          elsif (
                url = (SiteSetting.try(:site_logo_small_url) || SiteSetting.logo_small_url)
              ).present?
            "#{Discourse.base_url}#{url}"
          end

        slack_username =
          if SiteSetting.chat_integration_slack_username.present?
            SiteSetting.chat_integration_slack_username
          else
            SiteSetting.title || "Discourse"
          end

        message = {
          channel: "##{channel_name}",
          username: slack_username,
          icon_url: icon_url,
          attachments: [],
        }

        summary = {
          fallback: content.truncate(100),
          author_name: sender,
          color: nil,
          text: full_content,
          mrkdwn_in: ["text"],
          title: content.truncate(100),
          title_link: url,
          thumb_url: nil,
        }

        message[:attachments].push(summary)

        DiscourseChatIntegration::Provider::SlackProvider.send_via_api(nil, channel, message)
      end
    end
  end
end
