# frozen_string_literal: true

module DiscourseChat
  module Provider
    module MattermostProvider
      PROVIDER_NAME = "mattermost".freeze
      PROVIDER_ENABLED_SETTING = :chat_integration_mattermost_enabled
      WEBHOOK_PARAMETERS = [
                          { key: "name", regex: '^\S*$', unique: true },
                          { key: "url", regex: '^\S*$', unique: false },
                          { key: "icon_url", regex: '^[\S]*$', unique: false },
                          { key: "excerpt_length", regex: '^\d\d*$', unique: false }
                       ]
      CHANNEL_PARAMETERS = [
                          { key: "webhook", regex: '^[\S]*$', unique: true },
                          { key: "identifier", regex: '^[@#]\S*$', unique: true }
                       ]

      def self.send_via_webhook(url, message)
        uri = URI(url)

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

      def self.mattermost_message(post, channel, icon_url, excerpt_length)
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
          text: post.excerpt(excerpt_length, text_entities: true, strip_links: true, remap_emoji: true),
          title: "#{topic.title} #{category} #{topic.tags.present? ? topic.tags.map(&:name).join(', ') : ''}",
          title_link: post.full_url,
        }

        message[:attachments].push(summary)
        message
      end

      def self.trigger_notification(post, channel)
        webhook_name = channel.data['webhook']

        if webhook_name.blank?
          url = SiteSetting.chat_integration_mattermost_webhook_url
          excerpt_length = SiteSetting.chat_integration_mattermost_excerpt_length
          icon_url = nil
        else
          webhooks = DiscourseChat::Webhook.with_provider(PROVIDER_NAME)
          webhook = webhooks.with_data_value('name', webhook_name).first
          if webhook.nil?
            error_key = 'chat_integration.provider.mattermost.errors.webhook_not_found'
            raise ::DiscourseChat::ProviderError.new info: { error_key: error_key, webhook: webhook_name }
          end

          url = webhook.data['url']
          icon_url = webhook.data['icon_url']
          excerpt_length = Integer(webhook.data['excerpt_length'])
        end

        if icon_url.blank?
          icon_url =
            if SiteSetting.chat_integration_mattermost_icon_url.present?
              UrlHelper.absolute(SiteSetting.chat_integration_mattermost_icon_url)
            elsif (small_url = (SiteSetting.try(:site_logo_small_url) || SiteSetting.logo_small_url)).present?
              UrlHelper.absolute(small_url)
            end
        end

        channel_id = channel.data['identifier']
        message = mattermost_message(post, channel_id, icon_url, excerpt_length)

        self.send_via_webhook(url, message)
      end

    end
  end
end

require_relative "mattermost_command_controller.rb"
