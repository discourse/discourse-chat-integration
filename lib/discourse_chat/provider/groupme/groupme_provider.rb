# frozen_string_literal: true
require 'securerandom'
module DiscourseChat::Provider::GroupmeProvider
    PROVIDER_NAME = "groupme".freeze
  
    PROVIDER_ENABLED_SETTING = :chat_integration_groupme_enabled
  
    CHANNEL_PARAMETERS = [
                          { key: "identifier", regex: '^[@#]\S*$', unique: true },
                          { key: "webhook_url", regex: '^https://api.groupme.com/v3/groups/*/messages'}
                         ]
  
    def self.generate_groupme_message(post, channel)
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

      data = {
          message: {
              source_guid: SecureRandom.uuid,
              text: post.excerpt(SiteSetting.chat_integration_groupme_excerpt_length, text_entities: true, strip_links: true, remap_emoji: true)
          }
      }

    end
  
    def self.send_via_webhook(message)
      # uri = URI(SiteSetting.chat_integration_groupme_webhook_url)
      # for loop through all the group IDs
      group_ids = SiteSetting.chat_integration_groupme_groupids.split(/\s*,\s*/)
      group_ids.each { |group_id|
        uri = URI("https://api.groupme.com/v3/groups/#{group_id}/messages?token=#{SiteSetting.chat_integration_groupme_access_token}")
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = (uri.scheme == 'https')
        req = Net::HTTP::Post.new(uri, 'Content-Type' => 'application/json')
        req.body = message.to_json
        response = http.request(req)
        unless response.kind_of? Net::HTTPSuccess
            if response.body.include?('invalid-channel')
              error_key = 'chat_integration.provider.groupme.errors.invalid_channel'
            else
              error_key = nil
            end
            raise ::DiscourseChat::ProviderError.new info: { error_key: error_key, request: req.body, response_code: response.code, response_body: response.body }
        end

      }
    end
  
    # ideally i would get it to post multiple messages in the
    # case that user wants multiple groupmes, only works if token 
    # can be re-used
    def self.trigger_notification(post, channel)
    #   channel_id = channel.data['identifier']
      data_package = generate_groupme_message(post)#, channel_id)
  
      self.send_via_webhook(data_package)
    end
  end
  