module DiscourseChat
  module Provider
    module DiscordProvider
      PROVIDER_NAME = "discord".freeze
      PROVIDER_ENABLED_SETTING = :chat_integration_discord_enabled
      CHANNEL_PARAMETERS = [
                        { key: "name", regex: '^\S+' },
                        { key: "webhook_url", regex: '^https:\/\/discordapp\.com\/api\/webhooks\/', unique: true, hidden: true }
                       ]

      def self.send_message(url, message)
        http = Net::HTTP.new("discordapp.com", 443)
        http.use_ssl = true

        uri = URI(url)

        req = Net::HTTP::Post.new(uri, 'Content-Type' => 'application/json')
        req.body = message.to_json
        response = http.request(req)

        return response
      end

      def self.ensure_protocol(url)
        return url if not url.start_with?('//')
        return 'http:' + url
      end

      def self.generate_discord_message(post)

        display_name = "@#{post.user.username}"
        full_name = post.user.name || ""

        if !(full_name.strip.empty?) && (full_name.strip.gsub(' ', '_').casecmp(post.user.username) != 0) && (full_name.strip.gsub(' ', '').casecmp(post.user.username) != 0)
          display_name = "#{full_name} @#{post.user.username}"
        end

        message = {
          embeds: [{
            title: post.topic.title,
            description: post.excerpt(SiteSetting.chat_integration_discord_excerpt_length, text_entities: true, strip_links: true, remap_emoji: true),
            url: post.full_url,
            author: {
              name: display_name,
              url: Discourse.base_url + "/u/" + post.user.username,
              icon_url: ensure_protocol(post.user.small_avatar_url)
            }
          }]
        }

        return message
      end

      def self.trigger_notification(post, channel)
        # Adding ?wait=true means that we actually get a success/failure response, rather than returning asynchronously
        webhook_url = channel.data['webhook_url'] + '?wait=true'

        message = generate_discord_message(post)

        response = send_message(webhook_url, message)

        if not response.kind_of? Net::HTTPSuccess
          error_key = nil
          raise ::DiscourseChat::ProviderError.new info: { error_key: error_key, message: message, response_body: response.body }
        end

      end

    end
  end
end
