module DiscourseChat::Provider::SlackProvider
  class SlackCommandController < DiscourseChat::Provider::HookController
    requires_provider ::DiscourseChat::Provider::SlackProvider::PROVIDER_NAME

    before_filter :slack_token_valid?, only: :command

    skip_before_filter :check_xhr,
                       :preload_json,
                       :verify_authenticity_token,
                       :redirect_to_login_if_required,
                       only: :command

    def command
      text = process_command(params)

      render json: { text: text }
    end

    def process_command(params)
      guardian = DiscourseChat::Manager.guardian

      tokens = params[:text].split(" ")

      # channel name fix
      channel_id =
        case params[:channel_name]
        when 'directmessage'
          "@#{params[:user_name]}"
        when 'privategroup'
          params[:channel_id]
        else
          "##{params[:channel_name]}"
        end

      provider = DiscourseChat::Provider::SlackProvider::PROVIDER_NAME

      channel = DiscourseChat::Channel.with_provider(provider).with_data_value('identifier',channel_id).first

      # Create channel if doesn't exist
      channel ||= DiscourseChat::Channel.create!(provider:provider, data:{identifier: channel_id})

      cmd = tokens.shift if tokens.size >= 1

      error_text = I18n.t("chat_integration.provider.slack.parse_error")

      case cmd
      when "watch", "follow", "mute"
        return error_text if tokens.empty?
        # If the first token in the command is a tag, this rule applies to all categories
        category_name = tokens[0].start_with?('tag:') ? nil : tokens.shift

        if category_name 
          category = Category.find_by(slug: category_name)
          unless category
            cat_list = (CategoryList.new(guardian).categories.map(&:slug)).join(', ')
            return I18n.t("chat_integration.provider.slack.not_found.category", name: category_name, list:cat_list)
          end
        else
          category = nil # All categories
        end

        tags = []
        # Every remaining token must be a tag. If not, abort and send help text
        while tokens.size > 0
          token = tokens.shift
          if token.start_with?('tag:')
            tag_name = token.sub(/^tag:/, '')
          else
            return error_text # Abort and send help text  
          end

          tag = Tag.find_by(name: tag_name)
          unless tag # If tag doesn't exist, abort
            return I18n.t("chat_integration.provider.slack.not_found.tag", name: tag_name)
          end
          tags.push(tag.name)
        end

        category_id = category.nil? ? nil : category.id
        case DiscourseChat::Helper.smart_create_rule(channel:channel, filter:cmd, category_id: category_id, tags:tags)
        when :created
          return I18n.t("chat_integration.provider.slack.create.created")
        when :updated
          return I18n.t("chat_integration.provider.slack.create.updated")
        else
          return I18n.t("chat_integration.provider.slack.create.error")
        end
      when "remove"
        return error_text unless tokens.size == 1

        rule_number = tokens[0].to_i
        return error_text unless rule_number.to_s == tokens[0] # Check we were given a number

        if DiscourseChat::Helper.delete_by_index(channel, rule_number)
          return I18n.t("chat_integration.provider.slack.delete.success")
        else
          return I18n.t("chat_integration.provider.slack.delete.error")
        end
      when "status"
        return DiscourseChat::Helper.status_for_channel(channel)
      when "help"
        return I18n.t("chat_integration.provider.slack.help")
      else
        return error_text
      end
      
    end

    def slack_token_valid?
      params.require(:token)

      if SiteSetting.chat_integration_slack_incoming_webhook_token.blank? ||
         SiteSetting.chat_integration_slack_incoming_webhook_token != params[:token]

        raise Discourse::InvalidAccess.new
      end
    end
  end

  class SlackEngine < ::Rails::Engine
    engine_name DiscourseChat::PLUGIN_NAME+"-slack"
    isolate_namespace DiscourseChat::Provider::SlackProvider
  end

  SlackEngine.routes.draw do
    post "command" => "slack_command#command"
  end

end



