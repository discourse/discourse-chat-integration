# frozen_string_literal: true

module DiscourseChat
  module Provider
    module MattermostProvider
      PROVIDER_NAME = "mattermost".freeze
      PROVIDER_ENABLED_SETTING = :chat_integration_mattermost_enabled
      CHANNEL_PARAMETERS = [
                          { key: "identifier", regex: '^[@#]\S*$', unique: true }
                       ]

      def self.send_via_webhook(message)

        uri = URI(SiteSetting.chat_integration_mattermost_webhook_url)

        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = (uri.scheme == 'https')
        req = Net::HTTP::Post.new(uri, 'Content-Type' => 'application/json')
        req.body = message.to_json
        response = http.request(req)

        unless response.kind_of? Net::HTTPSuccess
          if response.body.include? "Couldn't find the channel"
            error_key = 'chat_integration.provider.mattermost.errors.channel_not_found'
          else
            error_key = nil
          end
          raise ::DiscourseChat::ProviderError.new info: { error_key: error_key, request: req.body, response_code: response.code, response_body: response.body }
        end

      end

      def self.mattermost_message(post, channel)
        display_name = "@#{post.user.username}"
        full_name = post.user.name || ""

        if !(full_name.strip.empty?) && (full_name.strip.gsub(' ', '_').casecmp(post.user.username) != 0) && (full_name.strip.gsub(' ', '').casecmp(post.user.username) != 0)
          display_name = "#{full_name} @#{post.user.username}"
        end

        topic = post.topic

        category = ''
        if topic.category&.uncategorized?
          category = "[#{I18n.t('uncategorized_category_name')}]"
        elsif topic.category
          category = (topic.category.parent_category) ? "[#{topic.category.parent_category.name}/#{topic.category.name}]" : "[#{topic.category.name}]"
        end

        icon_url =
          if SiteSetting.chat_integration_mattermost_icon_url.present?
            UrlHelper.absolute(SiteSetting.chat_integration_mattermost_icon_url)
          elsif (url = (SiteSetting.try(:site_logo_small_url) || SiteSetting.logo_small_url)).present?
            UrlHelper.absolute(url)
          end

        message = {
          channel: channel,
          username: SiteSetting.title || "Discourse",
          icon_url: icon_url,
          attachments: []
        }

        summary = {
          fallback: "#{topic.title} - #{display_name}",
          author_name: display_name,
          author_icon: post.user.small_avatar_url,
          color: topic.category ? "##{topic.category.color}" : nil,
          text: post.excerpt(SiteSetting.chat_integration_mattermost_excerpt_length, text_entities: true, strip_links: true, remap_emoji: true),
          title: "#{topic.title} #{category} #{topic.tags.present? ? topic.tags.map(&:name).join(', ') : ''}",
          title_link: post.full_url,
        }

        message[:attachments].push(summary)
        message
      end

      def self.trigger_notification(post, channel, rule)
        channel_id = channel.data['identifier']
        message = mattermost_message(post, channel_id)

        self.send_via_webhook(message)
      end

    end
  end
end

require_relative "mattermost_command_controller.rb"
