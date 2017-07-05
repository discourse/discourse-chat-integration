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
      channel =
        case params[:channel_name]
        when 'directmessage'
          "@#{params[:user_name]}"
        when 'privategroup'
          params[:channel_id]
        else
          "##{params[:channel_name]}"
        end

      cmd = tokens.shift if tokens.size >= 1

      error_text = I18n.t("chat_integration.provider.slack.error")

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
          tags.push(tag)
        end

        return "You want to watch post in #{category.nil? ? '(all)':category.name} with tags #{tags.map(&:name)}. Sorry, I can't do that yet"

      when "remove"
        return "You want to remove a rule. Sorry, I don't know how to do that yet"
      when "status"
        return DiscourseChat::Helper.status_for_channel(DiscourseChat::Provider::SlackProvider::PROVIDER_NAME, channel)
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



