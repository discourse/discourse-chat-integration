# frozen_string_literal: true
module DiscourseChat::Provider::GroupmeProvider
  PROVIDER_NAME = "groupme".freeze
  PROVIDER_ENABLED_SETTING = :chat_integration_groupme_enabled
  CHANNEL_PARAMETERS = [
      { key: "groupme_instance_name", regex: '[\s\S]*', unique: true }
  ]

  def self.generate_groupme_message(post)
    display_name = "@#{post.user.username}"
    full_name = post.user.name || ""
    if !(full_name.strip.empty?) && (full_name.strip.gsub(' ', '_').casecmp(post.user.username) != 0) && (full_name.strip.gsub(' ', '').casecmp(post.user.username) != 0)
      display_name = "#{full_name} @#{post.user.username}"
    end

    topic = post.topic

    category = ''
    if topic.category&.uncategorized?
      category = "#{I18n.t('uncategorized_category_name')}"
    elsif topic.category
      category = (topic.category.parent_category) ? "#{topic.category.parent_category.name}/#{topic.category.name}" : "#{topic.category.name}"
    end
    pre_post_text = "#{display_name} Posted to #{SiteSetting.title}\n\nTopic: #{topic.title} [#{category}]"
    read_more = "(Read More: #{post.full_url})"
    post_excerpt = "#{post.excerpt(SiteSetting.chat_integration_groupme_excerpt_length, text_entities: true, strip_links: true, remap_emoji: true)}"
    data = {
      text: "#{pre_post_text}\n\n#{post_excerpt}\n#{read_more}"
    }
    data
  end

  def self.send_via_webhook(message, channel)
    # loop through all the bot IDs
    last_error_raised = nil
    num_errors = 0
    # split on commas, but remove leading/trailing spaces
    bot_ids = SiteSetting.chat_integration_groupme_bot_ids.split(/\s*,\s*/)
    instance_names = SiteSetting.chat_integration_groupme_instance_names.split(/\s*,\s*/)

    unless instance_names.length() == bot_ids.length()
      instance_names = [I18n.t('chat_integration.provider.groupme.errors.instance_names_issue')] * bot_ids.length()
    end

    name_to_id = Hash[instance_names.zip(bot_ids)]
    user_input_channel = channel.data['groupme_instance_name'].strip
    unless user_input_channel.eql? 'all'
      instance_names = [user_input_channel]
    end
    instance_names.each { |instance_name|
      bot_id = name_to_id["#{instance_name}"]
      uri = URI("https://api.groupme.com/v3/bots/post")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == 'https')
      req = Net::HTTP::Post.new(uri, 'Content-Type' => 'application/json')
      message[:bot_id] = bot_id
      req.body = message.to_json
      response = http.request(req)
      unless response.kind_of? Net::HTTPSuccess
        num_errors += 1
        if response.code.to_s == '404'
          error_key = 'chat_integration.provider.groupme.errors.not_found'
        else
          error_key = nil
        end
        last_error_raised = { error_key: error_key, groupme_name: instance_name, bot_id: bot_id, request: req.body, response_code: response.code, response_body: response.body }
      end
    }
    if last_error_raised
      successfully_sent = instance_names.length() - num_errors
      last_error_raised[:success_rate] = "#{successfully_sent}/#{instance_names.length()}"
      raise ::DiscourseChat::ProviderError.new info: last_error_raised
    end
  end

  def self.trigger_notification(post, channel, rule)
    data_package = generate_groupme_message(post)
    self.send_via_webhook(data_package, channel)
  end
end
