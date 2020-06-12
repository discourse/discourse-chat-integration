# frozen_string_literal: true

module DiscourseChat
  module Provider
    module ZulipProvider
      PROVIDER_NAME = "zulip".freeze
      PROVIDER_ENABLED_SETTING = :chat_integration_zulip_enabled
      CHANNEL_PARAMETERS = [
                        { key: "stream", unique: true, regex: '^\S+' },
                        { key: "subject", unique: true, regex: '^\S+' },
                       ]

      def self.send_message(message)
        uri = URI("#{SiteSetting.chat_integration_zulip_server}/api/v1/messages")

        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = (uri.scheme == 'https')

        req = Net::HTTP::Post.new(uri)
        req.basic_auth(SiteSetting.chat_integration_zulip_bot_email_address, SiteSetting.chat_integration_zulip_bot_api_key)
        req.set_form_data(message)

        response = http.request(req)

        response
      end

      def self.generate_zulip_message(post, stream, subject)
        display_name = "@#{post.user.username}"
        full_name = post.user.name || ""

        if !(full_name.strip.empty?) && (full_name.strip.gsub(' ', '_').casecmp(post.user.username) != 0) && (full_name.strip.gsub(' ', '').casecmp(post.user.username) != 0)
          display_name = "#{full_name} @#{post.user.username}"
        end

        message = I18n.t('chat_integration.provider.zulip.message', user: display_name,
                                                                    post_url: post.full_url,
                                                                    title: post.topic.title,
                                                                    excerpt: post.excerpt(SiteSetting.chat_integration_zulip_excerpt_length, text_entities: true, strip_links: true, remap_emoji: true))

        data = {
          type: 'stream',
          to: stream,
          subject: subject,
          content: message
        }
      end

      def self.trigger_notification(post, channel, rule)

        stream = channel.data['stream']
        subject = channel.data['subject']

        message = self.generate_zulip_message(post, stream, subject)

        response = send_message(message)

        if !response.kind_of?(Net::HTTPSuccess)
          error_key = nil
          error_key = 'chat_integration.provider.zulip.errors.does_not_exist' if response.body.include?('does not exist')
          raise ::DiscourseChat::ProviderError.new info: { error_key: error_key, message: message, response_code: response.code, response_body: response.body }
        end

      end

    end
  end
end
