module DiscourseChat
  module Manager
    KEY_PREFIX = 'category_'.freeze

    def self.guardian
      Guardian.new(User.find_by(username: SiteSetting.chat_discourse_username))
    end

    def self.get_store_key(cat_id = nil)
      "#{KEY_PREFIX}#{cat_id.present? ? cat_id : '*'}"
    end

    def self.get_all_rules
      rules = []
      PluginStoreRow.where(plugin_name: DiscourseChat::PLUGIN_NAME)
        .where("key ~* :pattern", pattern: "^#{DiscourseChat::Manager::KEY_PREFIX}.*")
        .each do |row|
        PluginStore.cast_value(row.type_name, row.value).each do |rule|
          category_id =
            if row.key == DiscourseChat::Manager.get_store_key
              nil
            else
              row.key.gsub!(DiscourseChat::Manager::KEY_PREFIX, '')
              row.key
            end

          rules << {
            provider: rule[:provider],
            channel: rule[:channel],
            filter: rule[:filter],
            category_id: category_id,
            tags: rule[:tags]
          }
        end
      end
      return rules
    end

    def self.get_rules_for_provider(provider)
      get_all_rules.select { |rule| rule[:provider] == provider }
    end

    def self.get_rules_for_category(cat_id = nil)      
      PluginStore.get(DiscourseChat::PLUGIN_NAME, get_store_key(cat_id)) || []
    end

    def self.trigger_notifications(post_id)
      Rails.logger.info("Triggering chat notifications for post #{post_id}")

      post = Post.find_by(id: post_id)

      # Abort if the chat_user doesn't have permission to see the post
      return if !guardian.can_see?(post) 

      # Abort if the post is blank, or is non-regular (e.g. a "topic closed" notification)
      return if post.blank? || post.post_type != Post.types[:regular]

      topic = post.topic

      # Abort if a private message (possible TODO: Add support for notifying about group PMs)
      return if topic.blank? || topic.archetype == Archetype.private_message

      # Load all the rules that apply to this topic's category
      matching_rules = get_rules_for_category(topic.category_id)

      if topic.category # Also load the rules for the wildcard category
        matching_rules += get_rules_for_category(nil)
      end

      # If tagging is enabled, thow away rules that don't apply to this topic
      if SiteSetting.tagging_enabled
        topic_tags = topic.tags.present? ? topic.tags.pluck(:name) : []
        matching_rules = matching_rules.select do |rule|
          next true if rule[:tags].nil? or rule[:tags].empty? # Filter has no tags specified
          any_tags_match = !((rule[:tags] & topic_tags).empty?)
          next any_tags_match # If any tags match, keep this filter, otherwise throw away
        end
      end

      # Sort by order of precedence (mute always wins; watch beats follow)
      precedence = { 'mute' => 0, 'watch' => 1, 'follow' => 2}
      sort_func = proc { |a, b| precedence[a[:filter]] <=> precedence[b[:filter]] }
      matching_rules = matching_rules.sort(&sort_func)

      # Take the first rule for each channel
      uniq_func = proc { |rule| rule.values_at(:provider, :channel) }
      matching_rules = matching_rules.uniq(&uniq_func)

      # If a matching rule is set to mute, we can discard it now
      matching_rules = matching_rules.select { |rule| rule[:filter] != "mute" }

      # If this is not the first post, discard all "follow" rules
      if not post.is_first_post?
        matching_rules = matching_rules.select { |rule| rule[:filter] != "follow" }
      end

      # All remaining rules now require a notification to be sent
      # If there are none left, abort
      return false if matching_rules.empty?

      # Loop through each rule, and trigger appropriate notifications
      matching_rules.each do |rule|
        Rails.logger.info("Sending notification to provider #{rule[:provider]}, channel #{rule[:channel]}")
        provider = ::DiscourseChat::Provider.get_by_name(rule[:provider])
        if provider
          provider.trigger_notification(post, rule[:channel])
        else
          puts "Can't find provider"
          # TODO: Handle when the provider does not exist
        end
      end

    end

    def self.create_rule(provider, channel, filter, category_id, tags)
      raise "Invalid filter" if !['mute','follow','watch'].include?(filter)

      data = get_rules_for_category(category_id)
      tags = Tag.where(name: tags).pluck(:name)
      tags = nil if tags.blank?

      data.push(provider: provider, channel: channel, filter: filter, tags: tags)
      PluginStore.set(DiscourseChat::PLUGIN_NAME, get_store_key(category_id), data)
    end

  end
end