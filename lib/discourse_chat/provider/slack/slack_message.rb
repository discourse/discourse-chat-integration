module DiscourseChat::Provider::SlackProvider
  class SlackMessage
    def initialize(raw_message, transcript)
      @raw = raw_message
      @transcript = transcript
    end

    def username
      if user
        user['name']
      elsif @raw.key?("username")
        @raw["username"]
      end
    end

    def avatar
      user["profile"]["image_24"] if user
    end

    def url
      channel_id = @transcript.channel_id
      ts = @raw['ts'].gsub('.', '')
      "https://slack.com/archives/#{channel_id}/p#{ts}"
    end

    def text
      text = @raw['text'].nil? ? "" : @raw['text']

      # Format links (don't worry about special cases @ # !)
      text = text.gsub(/<(.*?)>/) do |match|
        group = $1
        parts = group.split('|')
        link = parts[0].start_with?('@', '#', '!') ? '' : parts[0]
        text = parts.length > 1 ? parts[1] : parts[0]

        if parts[0].start_with?('@')
          user = @transcript.users.find { |u| u["id"] == parts[0].gsub('@', '') } || parts[0]
          next "@#{user['name']}"
        end

        "[#{text}](#{link})"
      end

      # Add an extra * to each side for bold
      text = text.gsub(/\*(.*?)\*/) do |match|
        "*#{match}*"
      end

      text
    end

    def attachments_string
      string = ""
      string += "\n" if !attachments.empty?
      attachments.each do |attachment|
        string += " - #{attachment}\n"
      end
      string
    end

    def processed_text_with_attachments
      self.text + attachments_string
    end

    def raw_text
      raw_text = @raw['text'].nil? ? "" : @raw['text']
      raw_text += attachments_string
      raw_text
    end

    def attachments
      attachments = []

      return attachments unless @raw.key?('attachments')

      @raw["attachments"].each do |attachment|
        next unless attachment.key?("fallback")
        attachments << attachment["fallback"]
      end

      attachments
    end

    def ts
      @raw["ts"]
    end

    private

    def user
      return nil unless user_id = @raw["user"]
      @transcript.users.find { |u| u["id"] == user_id }
    end
  end
end
