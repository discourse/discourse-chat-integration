# frozen_string_literal: true

module DiscourseChat
  module Provider
    module MatrixProvider
      PROVIDER_NAME = "matrix".freeze
      PROVIDER_ENABLED_SETTING = :chat_integration_matrix_enabled
      CHANNEL_PARAMETERS = [
                        { key: "name", regex: '^\S+' },
                        { key: "room_id", regex: '^\!\S+:\S+$', unique: true, hidden: true }
                       ]

      def self.send_message(room_id, message)
        homeserver = SiteSetting.chat_integration_matrix_homeserver
        event_type = 'm.room.message'
        uid = Time.now.to_i

        url_params = URI.encode_www_form(access_token: SiteSetting.chat_integration_matrix_access_token)

        url = "#{homeserver}/_matrix/client/r0/rooms/#{CGI::escape(room_id)}/send/#{event_type}/#{uid}"

        uri = URI([url, url_params].join('?'))

        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true

        req = Net::HTTP::Put.new(uri, 'Content-Type' => 'application/json')
        req.body = message.to_json
        response = http.request(req)

        response
      end

      def self.generate_matrix_message(post)

        display_name = "@#{post.user.username}"
        full_name = post.user.name || ""

        if !(full_name.strip.empty?) && (full_name.strip.gsub(' ', '_').casecmp(post.user.username) != 0) && (full_name.strip.gsub(' ', '').casecmp(post.user.username) != 0)
          display_name = "#{full_name} @#{post.user.username}"
        end

        message = {
          msgtype: SiteSetting.chat_integration_matrix_use_notice ? 'm.notice' : 'm.text',
          body: I18n.t('chat_integration.provider.matrix.text_message',                           user: display_name,
                                                                                                  post_url: post.full_url,
                                                                                                  title: post.topic.title),
          format: 'org.matrix.custom.html',
          formatted_body: I18n.t('chat_integration.provider.matrix.formatted_message',                           user: display_name,
                                                                                                                 post_url: post.full_url,
                                                                                                                 title: post.topic.title,
                                                                                                                 excerpt: post.excerpt(SiteSetting.chat_integration_matrix_excerpt_length, text_entities: true, strip_links: true, remap_emoji: true))

        }

        message
      end

      def self.trigger_notification(post, channel, rule)
        message = generate_matrix_message(post)

        response = send_message(channel.data['room_id'], message)

        if !response.kind_of?(Net::HTTPSuccess)
          error_key = nil
          begin
            responseData = JSON.parse(response.body)
            if responseData['errcode'] == "M_UNKNOWN_TOKEN"
              error_key = 'chat_integration.provider.matrix.errors.unknown_token'
            elsif responseData['errcode'] == "M_UNKNOWN"
              error_key = 'chat_integration.provider.matrix.errors.unknown_room'
            end
          ensure
            raise ::DiscourseChat::ProviderError.new info: { error_key: error_key, message: message, response_body: response.body }
          end
        end

      end

    end
  end
end
