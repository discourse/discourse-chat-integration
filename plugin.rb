# name: discourse-chat
# about: This plugin integrates discourse with a number of chat providers
# version: 0.1
# url: https://github.com/discourse/discourse-chat

enabled_site_setting :chat_enabled

after_initialize do

  module ::DiscourseChat
    PLUGIN_NAME = "discourse-chat".freeze

    class Engine < ::Rails::Engine
      engine_name DiscourseChat::PLUGIN_NAME
      isolate_namespace DiscourseChat
    end
  end

  require_relative "lib/provider"
  require_relative "lib/manager"

  DiscourseEvent.on(:post_created) do |post|
    if SiteSetting.chat_enabled?
      ::DiscourseChat::Manager.trigger_notifications(post.id)
    end
  end

  class ::DiscourseChat::ChatController < ::ApplicationController
    requires_plugin DiscourseChat::PLUGIN_NAME

    def list
      requested_provider = params[:provider]

      providers = ::DiscourseChat::Provider.providers.map {|x| x::PROVIDER_NAME}

      if requested_provider.nil? 
        requested_provider = providers[0]
      end

      if not providers.include? requested_provider 
        raise Discourse::NotFound
      end

      rules = DiscourseChat::Manager.get_rules_for_provider(requested_provider)

      out = {provider: requested_provider, providers: providers, rules: rules}

      render json: out
    end

  end

  require_dependency 'admin_constraint'


  add_admin_route 'chat.menu_title', 'chat'

  DiscourseChat::Engine.routes.draw do
    get "(.:format)" => "chat#list" # TODO: Fix this hack
    get "/:provider" => "chat#list"
  end

  Discourse::Application.routes.append do
    mount ::DiscourseChat::Engine, at: '/admin/plugins/chat', constraints: AdminConstraint.new
  end

end
