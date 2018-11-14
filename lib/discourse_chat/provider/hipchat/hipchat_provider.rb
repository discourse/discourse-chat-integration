module DiscourseChat
  module Provider
    module HipchatProvider
      PROVIDER_NAME = "hipchat".freeze
      PROVIDER_ENABLED_SETTING = :chat_integration_hipchat_enabled
      CHANNEL_PARAMETERS = [
                        { key: "name", regex: '^\S+' },
                        { key: "webhook_url", regex: '^\S+$', unique: true, hidden: true },
                        { key: "color", regex: '^(yellow|green|red|purple|gray|random)$' }
                       ]

      def self.send_message(url, message)
        uri = URI(url)

        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true

        req = Net::HTTP::Post.new(uri, 'Content-Type' => 'application/json')
        req.body = message.to_json
        response = http.request(req)

        return response
      end

      def self.generate_hipchat_message(post)

        display_name = "@#{post.user.username}"
        full_name = post.user.name || ""

        if !(full_name.strip.empty?) && (full_name.strip.gsub(' ', '_').casecmp(post.user.username) != 0) && (full_name.strip.gsub(' ', '').casecmp(post.user.username) != 0)
          display_name = "#{full_name} @#{post.user.username}"
        end

        topic = post.topic

        message_text = I18n.t(
            "chat_integration.provider.hipchat.message",
            user: display_name,
            post_url: post.full_url,
            title: CGI::escapeHTML(topic.title),
          )

        icon_url =
          if SiteSetting.chat_integration_hipchat_icon_url.present?
            UrlHelper.absolute(SiteSetting.chat_integration_hipchat_icon_url)
          elsif (url = (SiteSetting.try(:site_logo_small_url) || SiteSetting.logo_small_url)).present?
            UrlHelper.absolute(url)
          end

        message = {
          message: message_text, # Fallback for clients that don't support the card markup
          notify: true,

          card: {
            style: "application",
            url: post.full_url,
            format: "medium",
            id: "discoursecard:#{post.id}",
            title: topic.title,
            description: post.excerpt(SiteSetting.chat_integration_hipchat_excerpt_length, text_entities: true, strip_links: true, remap_emoji: true),
            icon: {
              url: icon_url,
            },
            activity: {
              html: message_text
            }
          }

        }

        return message
      end

      def self.trigger_notification(post, channel)

        webhook_url = channel.data['webhook_url']

        message = generate_hipchat_message(post)

        message[:color] = channel.data['color']

        response = send_message(webhook_url, message)

        if !response.kind_of?(Net::HTTPSuccess)
          error_key = nil
          raise ::DiscourseChat::ProviderError.new info: { error_key: error_key, message: message, response_body: response.body }
        end

      end

    end
  end
end
