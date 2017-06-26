# name: discourse-chat
# about: This plugin integrates discourse with a number of chat providers
# version: 0.1
# url: https://github.com/discourse/discourse-chat

enabled_site_setting :discourse_chat_enabled

after_initialize do

  module ::DiscourseChat
    PLUGIN_NAME = "discourse-chat".freeze

    class Engine < ::Rails::Engine
      engine_name DiscourseChat::PLUGIN_NAME
      isolate_namespace DiscourseChat
    end
  end

  require_relative "lib/integration"

  class ::DiscourseChat::ChatController < ::ApplicationController
    requires_plugin DiscourseChat::PLUGIN_NAME

    def list_integrations
      render json: ::DiscourseChat::Integration.integrations.map {|x| x::INTEGRATION_NAME}
    end

  end

  require_dependency 'admin_constraint'


  add_admin_route 'chat.menu_title', 'chat'

  DiscourseChat::Engine.routes.draw do
    get "/list-integrations" => "chat#list_integrations", constraints: AdminConstraint.new
  end

  Discourse::Application.routes.prepend do
    mount ::DiscourseChat::Engine, at: "/chat"
  end

  Discourse::Application.routes.append do
    get '/admin/plugins/chat' => 'admin/plugins#index', constraints: StaffConstraint.new
  end

end
