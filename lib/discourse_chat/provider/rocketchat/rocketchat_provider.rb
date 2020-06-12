# frozen_string_literal: true

module DiscourseChat::Provider::RocketchatProvider
  PROVIDER_NAME = "rocketchat".freeze

  PROVIDER_ENABLED_SETTING = :chat_integration_rocketchat_enabled

  CHANNEL_PARAMETERS = [
                        { key: "identifier", regex: '^[@#]\S*$', unique: true }
                       ]

  def self.rocketchat_message(post, channel)
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

    message = {
      channel: channel,
      attachments: []
    }

    summary = {
      fallback: "#{topic.title} - #{display_name}",
      author_name: display_name,
      author_icon: post.user.small_avatar_url,
      color: topic.category ? "##{topic.category.color}" : nil,
      text: post.excerpt(SiteSetting.chat_integration_rocketchat_excerpt_length, text_entities: true, strip_links: true, remap_emoji: true),
      mrkdwn_in: ["text"],
      title: "#{topic.title} #{category} #{topic.tags.present? ? topic.tags.map(&:name).join(', ') : ''}",
      title_link: post.full_url
    }

    message[:attachments].push(summary)

    message
  end

  def self.send_via_webhook(message)
    uri = URI(SiteSetting.chat_integration_rocketchat_webhook_url)

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == 'https')

    req = Net::HTTP::Post.new(uri, 'Content-Type' => 'application/json')
    req.body = message.to_json
    response = http.request(req)

    unless response.kind_of? Net::HTTPSuccess
      if response.body.include?('invalid-channel')
        error_key = 'chat_integration.provider.rocketchat.errors.invalid_channel'
      else
        error_key = nil
      end
      raise ::DiscourseChat::ProviderError.new info: { error_key: error_key, request: req.body, response_code: response.code, response_body: response.body }
    end

  end

  def self.trigger_notification(post, channel, rule)
    channel_id = channel.data['identifier']
    message = rocketchat_message(post, channel_id)

    self.send_via_webhook(message)
  end
end
