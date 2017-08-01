module DiscourseChat
  module Manager

    def self.guardian
      Guardian.new(User.find_by(username: SiteSetting.chat_integration_discourse_username))
    end

    def self.trigger_notifications(post_id)
      Rails.logger.info("Triggering chat notifications for post #{post_id}")

      post = Post.find_by(id: post_id)

      # Abort if the chat_user doesn't have permission to see the post
      return if !guardian.can_see?(post) 

      # Abort if the post is blank, or is non-regular (e.g. a "topic closed" notification)
      return if post.blank? || post.post_type != Post.types[:regular]

      topic = post.topic

      # Abort if topic is blank... this should never be the case
      return if topic.blank?

      # If it's a private message, filter rules by groups, otherwise filter rules by category
      if topic.archetype == Archetype.private_message
        group_ids_with_access = topic.topic_allowed_groups.pluck(:group_id)
        return if group_ids_with_access.empty?
        matching_rules = DiscourseChat::Rule.with_type('group_message').with_group_ids(group_ids_with_access)
      else
        matching_rules = DiscourseChat::Rule.with_category_id(topic.category_id)
        if topic.category # Also load the rules for the wildcard category
          matching_rules += DiscourseChat::Rule.with_category_id(nil)
        end
      end

      # If tagging is enabled, thow away rules that don't apply to this topic
      if SiteSetting.tagging_enabled
        topic_tags = topic.tags.present? ? topic.tags.pluck(:name) : []
        matching_rules = matching_rules.select do |rule|
          next true if rule.tags.nil? or rule.tags.empty? # Filter has no tags specified
          any_tags_match = !((rule.tags & topic_tags).empty?)
          next any_tags_match # If any tags match, keep this filter, otherwise throw away
        end
      end

      # Sort by order of precedence (mute always wins; watch beats follow)
      precedence = { 'mute' => 0, 'watch' => 1, 'follow' => 2}
      sort_func = proc { |a, b| precedence[a.filter] <=> precedence[b.filter] }
      matching_rules = matching_rules.sort(&sort_func)

      # Take the first rule for each channel
      uniq_func = proc { |rule| [rule.channel_id] }
      matching_rules = matching_rules.uniq(&uniq_func)

      # If a matching rule is set to mute, we can discard it now
      matching_rules = matching_rules.select { |rule| rule.filter != "mute" }

      # If this is not the first post, discard all "follow" rules
      if not post.is_first_post?
        matching_rules = matching_rules.select { |rule| rule.filter != "follow" }
      end

      # All remaining rules now require a notification to be sent
      # If there are none left, abort
      return false if matching_rules.empty?

      # Loop through each rule, and trigger appropriate notifications
      matching_rules.each do |rule|
        # If there are any issues, skip to the next rule
        next unless channel = rule.channel
        next unless provider = ::DiscourseChat::Provider.get_by_name(channel.provider)
        next unless is_enabled = ::DiscourseChat::Provider.is_enabled(provider)

        begin
          provider.trigger_notification(post, channel)
          channel.update_attribute('error_key', nil) if channel.error_key
        rescue => e
          if e.class == DiscourseChat::ProviderError and e.info.key?(:error_key) and !e.info[:error_key].nil?
            channel.update_attribute('error_key', e.info[:error_key])
          else
            channel.update_attribute('error_key','chat_integration.channel_exception')
          end

          # Log the error
          Discourse.handle_job_exception(e,
            message: "Triggering notifications failed",
            extra: { provider_name: provider::PROVIDER_NAME,
                     channel: rule.channel,
                     post_id: post.id,
                     error_info: e.class == DiscourseChat::ProviderError ? e.info : nil }
          )
        end
        
      end

    end


  end
end