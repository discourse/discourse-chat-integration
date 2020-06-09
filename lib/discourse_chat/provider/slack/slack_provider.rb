# frozen_string_literal: true

module DiscourseChat::Provider::SlackProvider
  PROVIDER_NAME = "slack".freeze

  PROVIDER_ENABLED_SETTING = :chat_integration_slack_enabled

  CHANNEL_PARAMETERS = [
                        { key: "identifier", regex: '^[@#]?\S*$', unique: true }
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
    if topic.category&.uncategorized?
      category = "[#{I18n.t('uncategorized_category_name')}]"
    elsif topic.category
      category = (topic.category.parent_category) ? "[#{topic.category.parent_category.name}/#{topic.category.name}]" : "[#{topic.category.name}]"
    end

    icon_url =
      if SiteSetting.chat_integration_slack_icon_url.present?
        "#{Discourse.base_url}#{SiteSetting.chat_integration_slack_icon_url}"
      elsif (url = (SiteSetting.try(:site_logo_small_url) || SiteSetting.logo_small_url)).present?
        "#{Discourse.base_url}#{url}"
      end

    slack_username =
      if SiteSetting.chat_integration_slack_username.present?
        SiteSetting.chat_integration_slack_username
      else
        SiteSetting.title || "Discourse"
      end

    message = {
      channel: channel,
      username: slack_username,
      icon_url: icon_url,
      attachments: []
    }

    summary = {
      fallback: "#{topic.title} - #{display_name}",
      author_name: display_name,
      author_icon: post.user.small_avatar_url,
      color: topic.category ? "##{topic.category.color}" : nil,
      text: excerpt(post),
      mrkdwn_in: ["text"],
      title: "#{topic.title} #{category} #{topic.tags.present? ? topic.tags.map(&:name).join(', ') : ''}",
      title_link: post.full_url,
      thumb_url: post.full_url
    }

    message[:attachments].push(summary)

    message
  end

  def self.send_via_api(post, channel, message)
    http = Net::HTTP.new("slack.com", 443)
    http.use_ssl = true

    response = nil
    uri = ""

    data = {
      token: SiteSetting.chat_integration_slack_access_token,
    }

    req = Net::HTTP::Post.new(URI('https://slack.com/api/chat.postMessage'))

    data = {
      token: SiteSetting.chat_integration_slack_access_token,
      username: message[:username],
      icon_url: message[:icon_url],
      channel: message[:channel].gsub('#', ''),
      attachments: message[:attachments].to_json
    }

    req.set_form_data(data)

    response = http.request(req)

    unless response.kind_of? Net::HTTPSuccess
      raise ::DiscourseChat::ProviderError.new info: { request: uri, response_code: response.code, response_body: response.body }
    end

    json = JSON.parse(response.body)

    unless json["ok"] == true
      if json.key?("error") && (json["error"] == ('channel_not_found') || json["error"] == ('is_archived'))
        error_key = 'chat_integration.provider.slack.errors.channel_not_found'
      else
        error_key = nil
      end
      raise ::DiscourseChat::ProviderError.new info: { error_key: error_key, request: uri, response_code: response.code, response_body: response.body }
    end

    response
  end

  def self.send_via_webhook(message)
    http = Net::HTTP.new("hooks.slack.com", 443)
    http.use_ssl = true
    req = Net::HTTP::Post.new(URI(SiteSetting.chat_integration_slack_outbound_webhook_url), 'Content-Type' => 'application/json')
    req.body = message.to_json
    response = http.request(req)

    unless response.kind_of? Net::HTTPSuccess
      if response.code.to_s == '403'
        error_key = 'chat_integration.provider.slack.errors.action_prohibited'
      elsif response.body == ('channel_not_found') || response.body == ('channel_is_archived')
        error_key = 'chat_integration.provider.slack.errors.channel_not_found'
      else
        error_key = nil
      end
      raise ::DiscourseChat::ProviderError.new info: { error_key: error_key, request: req.body, response_code: response.code, response_body: response.body }
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

require_relative "slack_message_formatter"
require_relative "slack_transcript"
require_relative "slack_message"
require_relative "slack_command_controller"
