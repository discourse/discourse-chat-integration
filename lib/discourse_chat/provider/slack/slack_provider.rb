module DiscourseChat::Provider::SlackProvider
  PROVIDER_NAME = "slack".freeze

  def self.excerpt(post, max_length = SiteSetting.chat_slack_discourse_excerpt_length)
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

    category = (topic.category.parent_category) ? "[#{topic.category.parent_category.name}/#{topic.category.name}]": "[#{topic.category.name}]"

    icon_url =
      if !SiteSetting.chat_slack_icon_url.blank?
        "#{Discourse.base_url}#{SiteSetting.chat_slack_icon_url}"
      elsif !SiteSetting.logo_small_url.blank?
        "#{Discourse.base_url}#{SiteSetting.logo_small_url}"
      end

    message = {
      channel: channel,
      username: SiteSetting.title,
      icon_url: icon_url,
      attachments: []
    }

    summary = {
      fallback: "#{topic.title} - #{display_name}",
      author_name: display_name,
      author_icon: post.user.small_avatar_url,
      color: "##{topic.category.color}",
      text: ::DiscourseSlack::Slack.excerpt(post),
      mrkdwn_in: ["text"]
    }

    record = ::PluginStore.get(DiscourseSlack::PLUGIN_NAME, "topic_#{post.topic.id}_#{channel}")

    if (SiteSetting.slack_access_token.empty? || post.is_first_post? || record.blank? || (record.present? &&  ((Time.now.to_i - record[:ts].split('.')[0].to_i)/ 60) >= 5 ))
      summary[:title] = "#{topic.title} #{(category == '[uncategorized]')? '' : category} #{topic.tags.present? ? topic.tags.map(&:name).join(', ') : ''}"
      summary[:title_link] = post.full_url
      summary[:thumb_url] = post.full_url
    end

    message[:attachments].push(summary)
    message
  end

  def self.trigger_notification(post, channel)
  	message = slack_message(post, channel)

		http = Net::HTTP.new("hooks.slack.com", 443)
    http.use_ssl = true

  	req = Net::HTTP::Post.new(URI(SiteSetting.slack_outbound_webhook_url), 'Content-Type' =>'application/json')
    req.body = message.to_json
    response = http.request(req)

  end
end