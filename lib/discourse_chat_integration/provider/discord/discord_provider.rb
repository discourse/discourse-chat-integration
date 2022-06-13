# frozen_string_literal: true
require "date"

module DiscourseChatIntegration
  module Provider
    module DiscordProvider
      PROVIDER_NAME = "discord".freeze
      PROVIDER_ENABLED_SETTING = :chat_integration_discord_enabled

      CHANNEL_PARAMETERS = [
        { key: "name", regex: '^\S+' },
        { key: "webhook_url", regex: '^https:\/\/discord\.com\/api\/webhooks\/', unique: true, hidden: true }
      ].freeze

      def self.send_message(url, message)
        http = Net::HTTP.new("discord.com", 443)
        http.use_ssl = true

        uri = URI(url)

        req = Net::HTTP::Post.new(uri, 'Content-Type' => 'application/json')
        req.body = message.to_json
        response = http.request(req)

        response
      end

      def self.ensure_protocol(url)
        return url if !url.start_with?('//')
        "http:#{url}"
      end

      def self.generate_discord_message(post, rule=nil)
        display_name = ::DiscourseChatIntegration::Helper.formatted_display_name(post.user)

        topic = post.topic

        category = '[uncategorized]'
        if topic.category
          category = (topic.category.parent_category) ? "#{topic.category.parent_category.name}/#{topic.category.name}" : "#{topic.category.name}"
        end

        prefix_message = ''
        if rule 
          prefix_message = build_prefix_message(post, rule)
        end

        image_url = build_embed_image(post)
        thumbnail_url = build_embed_thumbnail(post)
        category_url = +"#{Discourse.base_url}/c"
        category_url << "/#{topic.category.parent_category.slug_path.join('/')}" if topic.category.parent_category_id
        category_url << "/#{topic.category.slug}"
        formatted_tags = topic.tags.present? ? topic.tags.map {|tag| "[#{tag.name}](#{Discourse.base_url}/tag/#{tag.name})"} : ["[none](#{Discourse.base_url}/tag/none)"]

        message = {
          content: prefix_message,
          embeds: [{
            title: "#{topic.title}",
            color: topic.category ? topic.category.color.to_i(16) : nil,
            description: post.excerpt(SiteSetting.chat_integration_discord_excerpt_length, text_entities: true, strip_links: true, remap_emoji: true),
            url: post.full_url,
            author: {
              name: display_name,
              url: Discourse.base_url + "/u/" + post.user.username,
              icon_url: ensure_protocol(post.user.small_avatar_url)
            },
            fields: [
              {
                name: "Category:",
                value: "[#{category}](#{category_url})",
                inline: true
              },
              {
                name: "Tags:",
                value: formatted_tags.join(", "),
                inline: true
              }  
            ],
            footer: {
              text: "aloha.pk",
              icon_url: SiteSetting.chat_integration_discord_message_footer_logo_url              
            },
            timestamp: DateTime.now.strftime('%Y-%m-%dT%H:%M:%S.%L%z'),
            image: {
              url: image_url
            },
            thumbnail: {
              url: thumbnail_url
            }
          }]
        }

        message
      end

      def self.build_prefix_message(post, rule)
        msg_fields = {'{username}' => post.user.username, '{title}' =>  "**#{post.topic.title}**", "{category}" => post.topic.category.name, "{views}" => "#{post.topic.views}", "{likes}" => "#{post.topic.like_count}"}    
        if post.is_first_post? && rule.new_topic_prefix
          return rule.new_topic_prefix.gsub(/{(.*?)}/, msg_fields)
        elsif !post.is_first_post? && rule.new_reply_prefix
          return rule.new_reply_prefix.gsub(/{(.*?)}/, msg_fields)
        else
          return ""
        end
      end

      def self.build_embed_image(post)
        if post.is_first_post?
          if post.topic.image_url.present?
            return post.topic.image_url
          else
            url = SiteSetting.chat_integration_discord_default_thumbnail_url
            return 
          end
        else
          return nil
        end
      end

      def self.build_embed_thumbnail(post)
        if !post.is_first_post?
          if post.topic.image_url.present?
            return post.topic.image_url
          else
            url = SiteSetting.chat_integration_discord_default_thumbnail_url
            return url
          end
        else
          return nil
        end
      end

      def self.trigger_notification(post, channel, rule)
        # Adding ?wait=true means that we actually get a success/failure response, rather than returning asynchronously
        webhook_url = "#{channel.data['webhook_url']}?wait=true"
        message = generate_discord_message(post, rule)
        response = send_message(webhook_url, message)

        if !response.kind_of?(Net::HTTPSuccess)
          raise ::DiscourseChatIntegration::ProviderError.new(info: {
            error_key: nil, message: message, response_body: response.body
          })
        end
      end

    end
  end
end
