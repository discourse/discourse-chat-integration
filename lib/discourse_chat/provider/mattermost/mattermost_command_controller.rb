module DiscourseChat::Provider::MattermostProvider
  class MattermostCommandController < DiscourseChat::Provider::HookController
    requires_provider ::DiscourseChat::Provider::MattermostProvider::PROVIDER_NAME

    before_filter :mattermost_token_valid?, only: :command

    skip_before_filter :check_xhr,
                       :preload_json,
                       :verify_authenticity_token,
                       :redirect_to_login_if_required,
                       only: :command

    def command
      text = process_command(params)
      
      render json: { 
        response_type: 'ephemeral',
        text: text 
      }
    end

    def process_command(params)

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

      provider = DiscourseChat::Provider::MattermostProvider::PROVIDER_NAME

      channel = DiscourseChat::Channel.with_provider(provider).with_data_value('identifier',channel_id).first

      # Create channel if doesn't exist
      channel ||= DiscourseChat::Channel.create!(provider:provider, data:{identifier: channel_id})

      return ::DiscourseChat::Helper.process_command(channel, tokens)
      
    end

    def mattermost_token_valid?
      params.require(:token)

      if SiteSetting.chat_integration_mattermost_incoming_webhook_token.blank? ||
         SiteSetting.chat_integration_mattermost_incoming_webhook_token != params[:token]

        raise Discourse::InvalidAccess.new
      end
    end
  end

  class MattermostEngine < ::Rails::Engine
    engine_name DiscourseChat::PLUGIN_NAME+"-mattermost"
    isolate_namespace DiscourseChat::Provider::MattermostProvider
  end

  MattermostEngine.routes.draw do
    post "command" => "mattermost_command#command"
  end

end



