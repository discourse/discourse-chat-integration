module DiscourseChat::Provider::SlackProvider
  PROVIDER_NAME = "slack".freeze

  PROVIDER_ENABLED_SETTING = :chat_integration_slack_enabled

  CHANNEL_PARAMETERS = [
                        {key: "identifier", regex: '^[@#]\S*$'}
                       ]

  def self.excerpt(post, max_length = SiteSetting.chat_integration_slack_excerpt_length)
    doc = Nokogiri::HTML.fragment(post.excerpt(max_length,
      remap_emoji: true,
      keep_onebox_source: true
    ))

    SlackMessageFormatter.format(doc.to_html)
  end

  def self.slack_message(post, channel)
    display_name = "@#{post.user.username}"
    full_name = post.user.name || ""

    if !(full_name.strip.empty?) && (full_name.strip.gsub(' ', '_').casecmp(post.user.username) != 0) && (full_name.strip.gsub(' ', '').casecmp(post.user.username) != 0)
      display_name = "#{full_name} @#{post.user.username}"
    end

    topic = post.topic

    category = ''
    if topic.category
      category = (topic.category.parent_category) ? "[#{topic.category.parent_category.name}/#{topic.category.name}]": "[#{topic.category.name}]"
    end

    icon_url =
      if !SiteSetting.chat_integration_slack_icon_url.blank?
        "#{Discourse.base_url}#{SiteSetting.chat_integration_slack_icon_url}"
      elsif !SiteSetting.logo_small_url.blank?
        "#{Discourse.base_url}#{SiteSetting.logo_small_url}"
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
      text: excerpt(post),
      mrkdwn_in: ["text"]
    }

    record = DiscourseChat.pstore_get("topic_#{post.topic.id}_#{channel}")

    if (SiteSetting.chat_integration_slack_access_token.empty? || post.is_first_post? || record.blank? || (record.present? &&  ((Time.now.to_i - record[:ts].split('.')[0].to_i)/ 60) >= 5 ))
      summary[:title] = "#{topic.title} #{(category == '[uncategorized]')? '' : category} #{topic.tags.present? ? topic.tags.map(&:name).join(', ') : ''}"
      summary[:title_link] = post.full_url
      summary[:thumb_url] = post.full_url
    end

    message[:attachments].push(summary)
    message
  end

  def self.send_via_api(post, channel, message)
  	http = Net::HTTP.new("slack.com", 443)
    http.use_ssl = true
  	
  	response = nil
    uri = ""
    record = DiscourseChat.pstore_get("slack_topic_#{post.topic.id}_#{channel}")

    if (record.present? && ((Time.now.to_i - record[:ts].split('.')[0].to_i)/ 60) < 5 && record[:message][:attachments].length < 5)
      attachments = record[:message][:attachments]
      attachments.concat message[:attachments]

      uri = URI("https://slack.com/api/chat.update" +
        "?token=#{SiteSetting.chat_integration_slack_access_token}" +
        "&username=#{CGI::escape(record[:message][:username])}" +
        "&text=#{CGI::escape(record[:message][:text])}" +
        "&channel=#{record[:channel]}" +
        "&attachments=#{CGI::escape(attachments.to_json)}" +
        "&ts=#{record[:ts]}"
      )
    else
      uri = URI("https://slack.com/api/chat.postMessage" +
        "?token=#{SiteSetting.chat_integration_slack_access_token}" +
        "&username=#{CGI::escape(message[:username])}" +
        "&icon_url=#{CGI::escape(message[:icon_url])}" +
        "&channel=#{ message[:channel].gsub('#', '') }" +
        "&attachments=#{CGI::escape(message[:attachments].to_json)}"
      )
    end

    response = http.request(Net::HTTP::Post.new(uri))

    unless response.kind_of? Net::HTTPSuccess 
      raise ::DiscourseChat::ProviderError.new info: {request: uri, response_code:response.code, response_body:response.body}
    end

    json = JSON.parse(response.body)

    unless json["ok"] == true
      if json.key?("error") and (json["error"] == 'channel_not_found' or json["error"] == 'is_archived')
        error_key = 'chat_integration.provider.slack.errors.channel_not_found'
      else
        error_key = json.to_s
      end
      raise ::DiscourseChat::ProviderError.new info: {error_key: error_key, request: uri, response_code:response.code, response_body:response.body}
    end

    DiscourseChat.pstore_set("slack_topic_#{post.topic.id}_#{channel}", JSON.parse(response.body) )
    response
  end

  def self.send_via_webhook(message)
  	http = Net::HTTP.new("hooks.slack.com", 443)
    http.use_ssl = true
  	req = Net::HTTP::Post.new(URI(SiteSetting.chat_integration_slack_outbound_webhook_url), 'Content-Type' =>'application/json')
    req.body = message.to_json
    response = http.request(req)

    unless response.kind_of? Net::HTTPSuccess
      if response.code.to_s == '403'
        error_key = 'chat_integration.provider.slack.errors.action_prohibited'
      elsif response.body == 'channel_not_found' or response.body == 'channel_is_archived'
        error_key = 'chat_integration.provider.slack.errors.channel_not_found'
      else
        error_key = nil
      end
      raise ::DiscourseChat::ProviderError.new info: {error_key: error_key, request: req.body, response_code:response.code, response_body:response.body}
    end

    
  end

  def self.trigger_notification(post, channel)
    channel_id = channel.data['identifier']
  	message = slack_message(post, channel_id)

		if SiteSetting.chat_integration_slack_access_token.empty?
			self.send_via_webhook(message)
		else
			self.send_via_api(post, channel_id, message)
		end

  end
end

require_relative "slack_message_formatter.rb"
require_relative "slack_command_controller.rb"