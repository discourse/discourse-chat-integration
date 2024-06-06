# frozen_string_literal: true

module DiscourseChatIntegration::Provider::SlackProvider
  PROVIDER_NAME = "slack"
  THREAD_CUSTOM_FIELD_PREFIX = "slack_thread_id_"

  # In the past, only one thread_ts was stored for each topic.
  # Now, we store one thread_ts per Slack channel.
  # Data will be automatically migrated when the next message is sent to the channel
  # This logic could be removed after 2022-12 - it's unlikely people will care about
  # threading messages to more-than-1-year-old Slack threads.
  THREAD_LEGACY = "thread"

  PROVIDER_ENABLED_SETTING = :chat_integration_slack_enabled

  CHANNEL_PARAMETERS = [{ key: "identifier", regex: '^[@#]?\S*$', unique: true }]

  require_dependency "topic"
  ::Topic.register_custom_field_type(
    DiscourseChatIntegration::Provider::SlackProvider::THREAD_LEGACY,
    :string,
  )

  def self.excerpt(post, max_length = SiteSetting.chat_integration_slack_excerpt_length)
    doc =
      Nokogiri::HTML5.fragment(
        post.excerpt(max_length, remap_emoji: true, keep_onebox_source: true),
      )

    SlackMessageFormatter.format(doc.to_html)
  end

  def self.slack_message(post, channel, filter)
    display_name = ::DiscourseChatIntegration::Helper.formatted_display_name(post.user)

    topic = post.topic

    category = ""
    if topic.category&.uncategorized?
      category = "[#{I18n.t("uncategorized_category_name")}]"
    elsif topic.category
      category =
        (
          if (topic.category.parent_category)
            "[#{topic.category.parent_category.name}/#{topic.category.name}]"
          else
            "[#{topic.category.name}]"
          end
        )
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

    message = { channel: channel, username: slack_username, icon_url: icon_url, attachments: [] }

    if filter == "thread" && thread_ts = get_slack_thread_ts(topic, channel)
      message[:thread_ts] = thread_ts
    end

    summary = {
      fallback: "#{topic.title} - #{display_name}",
      author_name: display_name,
      author_icon: post.user.small_avatar_url,
      color: topic.category ? "##{topic.category.color}" : nil,
      text: excerpt(post),
      mrkdwn_in: ["text"],
      title:
        "#{topic.title} #{category} #{topic.tags.present? ? topic.tags.map(&:name).join(", ") : ""}",
      title_link: post.full_url,
      thumb_url: post.full_url,
    }

    message[:attachments].push(summary)

    message
  end

  def self.send_via_api(post, channel, message)
    http = slack_api_http

    response = nil
    uri = ""

    # <!--SLACK_CHANNEL_ID=#{@channel_id};SLACK_TS=#{@requested_thread_ts}-->
    slack_thread_regex = /<!--SLACK_CHANNEL_ID=([^;.]+);SLACK_TS=([0-9]{10}.[0-9]{6})-->/

    req = Net::HTTP::Post.new(URI("https://slack.com/api/chat.postMessage"))

    data = {
      token: SiteSetting.chat_integration_slack_access_token,
      username: message[:username],
      icon_url: message[:icon_url],
      channel: message[:channel].gsub("#", ""),
      attachments: message[:attachments].to_json,
    }

    if post
      if message.key?(:thread_ts)
        data[:thread_ts] = message[:thread_ts]
      elsif (match = slack_thread_regex.match(post.raw)) && match.captures[0] == channel
        data[:thread_ts] = match.captures[1]
        set_slack_thread_ts(post.topic, channel, match.captures[1])
      end
    end

    req.set_form_data(data)

    response = http.request(req)

    unless response.kind_of? Net::HTTPSuccess
      raise ::DiscourseChatIntegration::ProviderError.new info: {
                                                            request: uri,
                                                            response_code: response.code,
                                                            response_body: response.body,
                                                          }
    end

    json = JSON.parse(response.body)

    unless json["ok"] == true
      if json.key?("error") &&
           (json["error"] == ("channel_not_found") || json["error"] == ("is_archived"))
        error_key = "chat_integration.provider.slack.errors.channel_not_found"
      else
        error_key = nil
      end
      raise ::DiscourseChatIntegration::ProviderError.new info: {
                                                            error_key: error_key,
                                                            request: uri,
                                                            response_code: response.code,
                                                            response_body: response.body,
                                                          }
    end

    ts = json.dig("message", "thread_ts") || json["ts"]
    set_slack_thread_ts(post.topic, channel, ts) if !ts.nil? && !post.nil?

    response
  end

  def self.send_via_webhook(message)
    http = FinalDestination::HTTP.new("hooks.slack.com", 443)
    http.use_ssl = true
    req =
      Net::HTTP::Post.new(
        URI(SiteSetting.chat_integration_slack_outbound_webhook_url),
        "Content-Type" => "application/json",
      )
    req.body = message.to_json
    response = http.request(req)

    unless response.kind_of? Net::HTTPSuccess
      if response.code.to_s == "403"
        error_key = "chat_integration.provider.slack.errors.action_prohibited"
      elsif response.body == ("channel_not_found") || response.body == ("channel_is_archived")
        error_key = "chat_integration.provider.slack.errors.channel_not_found"
      else
        error_key = nil
      end
      raise ::DiscourseChatIntegration::ProviderError.new info: {
                                                            error_key: error_key,
                                                            request: req.body,
                                                            response_code: response.code,
                                                            response_body: response.body,
                                                          }
    end
  end

  def self.trigger_notification(post, channel, rule)
    channel_id = channel.data["identifier"]
    filter = rule.nil? ? "" : rule.filter
    message = slack_message(post, channel_id, filter)

    if SiteSetting.chat_integration_slack_access_token.empty?
      self.send_via_webhook(message)
    else
      self.send_via_api(post, channel_id, message)
    end
  end

  def self.slack_api_http
    http = FinalDestination::HTTP.new("slack.com", 443)
    http.use_ssl = true
    http.read_timeout = 5 # seconds
    http
  end

  def self.get_slack_thread_ts(topic, channel)
    field = TopicCustomField.where(topic: topic, name: "#{THREAD_CUSTOM_FIELD_PREFIX}#{channel}")
    field.pick(:value) || topic.custom_fields[THREAD_LEGACY]
  end

  def self.set_slack_thread_ts(topic, channel, value)
    TopicCustomField.upsert(
      {
        topic_id: topic.id,
        name: "#{THREAD_CUSTOM_FIELD_PREFIX}#{channel}",
        value: value,
        created_at: Time.zone.now,
        updated_at: Time.zone.now,
      },
      unique_by: :index_topic_custom_fields_on_topic_id_and_slack_thread_id,
    )
  end
end

require_relative "slack_message_formatter"
require_relative "slack_transcript"
require_relative "slack_message"
require_relative "slack_command_controller"
