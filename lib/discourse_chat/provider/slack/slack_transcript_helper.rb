module DiscourseChat::Provider::SlackProvider
  class SlackMessage
    def initialize(raw_message, transcript)
      @raw = raw_message
      @transcript = transcript
    end

    def username
      if user
        return user['name']
      elsif @raw.key?("username")
        return @raw["username"]
      end
    end

    def avatar
      return nil unless user
      return user["profile"]["image_24"]
    end

    def url
      channel_id = @transcript.channel_id
      ts = @raw['ts'].gsub('.', '')

      return "https://slack.com/archives/#{channel_id}/p#{ts}"
    end

    def text
      text = @raw["text"]

      # Format links (don't worry about special cases @ # !)
      text = text.gsub(/<(.*?)>/) do |match|
        group = $1
        parts = group.split('|')
        link = parts[0].start_with?('@', '#', '!') ? '' : parts[0]
        text = parts.length > 1 ? parts[1] : parts[0]

        if parts[0].start_with?('@')
          user = @transcript.users.find { |u| u["id"] == parts[0].gsub('@', '') }
          next "@#{user['name']}"
        end

        "[#{text}](#{link})"
      end

      # Add an extra * to each side for bold
      text = text.gsub(/\*(.*?)\*/) do |match|
        "*#{match}*"
      end

      return text
    end

    def raw_text
      @raw['text']
    end

    def attachments
      attachments = []

      return attachments unless @raw.key?('attachments')

      @raw["attachments"].each do |attachment|
        next unless attachment.key?("fallback")
        attachments << attachment["fallback"]
      end

      return attachments
    end

    def ts
      @raw["ts"]
    end

    private
      def user
        return nil unless user_id = @raw["user"]
        users = @transcript.users
        user = users.find { |u| u["id"] == user_id }
      end

  end

  class SlackTranscript
    attr_reader :users, :channel_id

    def initialize(raw_history:, raw_users:, channel_id:, channel_name:, requested_messages: nil, first_message_ts: nil, last_message_ts: nil)

      requested_messages ||= 10

      raw_messages = raw_history['messages'].reverse
      # Build some message objects
      @messages = []
      raw_messages.each_with_index do |message, index|
        next unless message["type"] == "message"
        this_message = SlackMessage.new(message, self)
        @messages << this_message

        # Auto set first and last based on requested_messages
        @first_message = this_message if index == raw_messages.length - requested_messages
        @last_message = this_message if index == raw_messages.length - 1
      end

      @first_message = @messages.find { |m| m.ts == first_message_ts } || @first_message if first_message_ts
      @last_message = @messages.find { |m| m.ts == last_message_ts } || @last_message if last_message_ts

      @first_message_index = @messages.index(@first_message)
      @last_message_index = @messages.index(@last_message)

      @users = raw_users['members']
      @channel_id = channel_id
      @channel_name = channel_name
    end

    def build_transcript
      post_content = "[quote]\n"
      post_content << "[**#{I18n.t('chat_integration.provider.slack.transcript.view_on_slack', name: @channel_name)}**](#{@first_message.url})\n"

      all_avatars = {}

      last_username = ''

      transcript_messages = @messages[@first_message_index..@last_message_index]

      transcript_messages.each do |m|
        same_user = m.username == last_username
        last_username = m.username

        unless same_user
          if avatar = m.avatar
            all_avatars[m.username] ||= avatar
          end

          post_content << "\n"
          post_content << "![#{m.username}] " if m.avatar
          post_content << "**@#{m.username}:** "
        end

        post_content << m.text

        m.attachments.each do |attachment|
          post_content << "\n> #{attachment}\n"
        end

        post_content << "\n"
      end

      post_content << "[/quote]\n\n"

      all_avatars.each do |username, url|
        post_content << "[#{username}]: #{url}\n"
      end

      return post_content
    end

    def build_slack_ui
      post_content = build_transcript
      secret = DiscourseChat::Helper.save_transcript(post_content)
      link = "#{Discourse.base_url}/chat-transcript/#{secret}"

      return { text: "<#{link}|#{I18n.t("chat_integration.provider.slack.transcript.post_to_discourse")}>",
               attachments: [
                {
                  pretext: I18n.t("chat_integration.provider.slack.transcript.first_message_pretext", n: @messages.length - @first_message_index),
                  fallback: "#{@first_message.username} - #{@first_message.raw_text}",
                  color: "#007AB8",
                  author_name: @first_message.username,
                  author_icon: @first_message.avatar,
                  text: @first_message.raw_text,
                  footer: I18n.t("chat_integration.provider.slack.transcript.posted_in", name: @channel_name),
                  ts: @first_message.ts,
                  callback_id: @last_message.ts,
                  actions: [
                    {
                        name: "first_message",
                        text: I18n.t("chat_integration.provider.slack.transcript.change_first_message"),
                        type: "select",
                        options: first_message_options = @messages[ [(@first_message_index - 20), 0].max .. @last_message_index]
                            .map { |m| { text: "#{m.username}: #{m.text}", value: m.ts } }
                    }
                  ],
                },
                {
                  pretext: I18n.t("chat_integration.provider.slack.transcript.last_message_pretext", n: @messages.length - @last_message_index),
                  fallback: "#{@last_message.username} - #{@last_message.raw_text}",
                  color: "#007AB8",
                  author_name: @last_message.username,
                  author_icon: @last_message.avatar,
                  text: @last_message.raw_text,
                  footer: I18n.t("chat_integration.provider.slack.transcript.posted_in", name: @channel_name),
                  ts: @last_message.ts,
                  callback_id: @first_message.ts,
                  actions: [
                    {
                        name: "last_message",
                        text: I18n.t("chat_integration.provider.slack.transcript.change_last_message"),
                        type: "select",
                        options: @messages[@first_message_index..(@last_message_index + 20)]
                            .map { |m| { text: "#{m.username}: #{m.text}", value: m.ts } }
                    }
                  ],
                }

               ]
             }
    end

    def self.load_user_data
      http = Net::HTTP.new("slack.com", 443)
      http.use_ssl = true

      req = Net::HTTP::Post.new(URI('https://slack.com/api/users.list'))
      req.set_form_data(token: SiteSetting.chat_integration_slack_access_token)
      response = http.request(req)
      return false unless response.kind_of? Net::HTTPSuccess
      json = JSON.parse(response.body)
      return false unless json['ok']
      return json
    end

    def self.load_chat_history(slack_channel_id:, count: 500)
      http = Net::HTTP.new("slack.com", 443)
      http.use_ssl = true

      req = Net::HTTP::Post.new(URI('https://slack.com/api/channels.history'))

      data = {
        token: SiteSetting.chat_integration_slack_access_token,
        channel: slack_channel_id,
        count: count
      }

      req.set_form_data(data)
      response = http.request(req)
      return false unless response.kind_of? Net::HTTPSuccess
      json = JSON.parse(response.body)
      return false unless json['ok']
      return json
    end

    def self.load_transcript(slack_channel_id:, channel_name:, requested_messages: nil, first_message_ts: nil, last_message_ts: nil)
      return false unless raw_users = self.load_user_data

      return false unless raw_history = self.load_chat_history(slack_channel_id: slack_channel_id)

      self.new(raw_history: raw_history,
               raw_users: raw_users,
               channel_id: slack_channel_id,
               channel_name: channel_name,
               requested_messages: requested_messages,
               first_message_ts: first_message_ts,
               last_message_ts: last_message_ts)
    end
  end

end
