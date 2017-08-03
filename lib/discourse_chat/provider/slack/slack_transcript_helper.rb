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
      text.gsub!(/<(.*?)>/) do |match|
        group = $1
        parts = group.split('|')
        link = parts[0].start_with?('@', '#', '!') ? '' : parts[0]
        text = parts.length > 1 ? parts[1] : parts[0]
        "[#{text}](#{link})"
      end

      # Add an extra * to each side for bold
      text.gsub!(/\*(.*?)\*/) do |match|
        "*#{match}*"
      end

      return text
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

    private
      def user
        return nil unless user_id = @raw["user"]
        users = @transcript.users
        user = users.find { |u| u["id"] == user_id }
      end

  end

  class SlackTranscript
    attr_reader :users, :channel_id

    def initialize(raw_history, raw_users, channel_id)
      # Build some message objects
      @messages = []
      raw_history['messages'].reverse.each do |message|
        next unless message["type"] == "message"
        @messages << SlackMessage.new(message, self)
      end

      @users = raw_users['members']
      @channel_id = channel_id
    end

    def build_transcript
      post_content = "[quote]\n"
      post_content << "[**#{I18n.t('chat_integration.provider.slack.view_on_slack')}**](#{@messages.first.url})\n"

      all_avatars = {}

      last_username = ''

      @messages.each do |m|
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

      return { text: "<#{link}|#{I18n.t("chat_integration.provider.slack.post_to_discourse")}>",
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

    def self.load_chat_history(slack_channel_id, messages_to_load)
      http = Net::HTTP.new("slack.com", 443)
      http.use_ssl = true

      req = Net::HTTP::Post.new(URI('https://slack.com/api/channels.history'))

      data = {
        token: SiteSetting.chat_integration_slack_access_token,
        channel: slack_channel_id,
        count: messages_to_load
      }

      req.set_form_data(data)
      response = http.request(req)
      return false unless response.kind_of? Net::HTTPSuccess
      json = JSON.parse(response.body)
      return false unless json['ok']
      return json
    end

    def self.load_transcript(slack_channel_id, messages_to_load)
      return false unless raw_users = self.load_user_data
      return false unless raw_history = self.load_chat_history(slack_channel_id, messages_to_load)

      self.new(raw_history, raw_users, slack_channel_id)
    end
  end

end
