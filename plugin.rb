# name: discourse-chat-integration
# about: This plugin integrates discourse with a number of chat providers
# version: 0.1
# url: https://github.com/discourse/discourse-chat-integration

enabled_site_setting :chat_integration_enabled


after_initialize do

  module ::DiscourseChat
    PLUGIN_NAME = "discourse-chat-integration".freeze

    class Engine < ::Rails::Engine
      engine_name DiscourseChat::PLUGIN_NAME
      isolate_namespace DiscourseChat
    end

    def self.plugin_name
      DiscourseChat::PLUGIN_NAME
    end

    def self.pstore_get(key)
      PluginStore.get(self.plugin_name, key)
    end

    def self.pstore_set(key, value)
      PluginStore.set(self.plugin_name, key, value)
    end

    def self.pstore_delete(key)
      PluginStore.remove(self.plugin_name, key)
    end
  end

  require_relative "lib/discourse_chat/provider"
  require_relative "lib/discourse_chat/manager"
  require_relative "lib/discourse_chat/rule"

  module ::Jobs
    class NotifyChats < Jobs::Base
      def execute(args)
        return if not SiteSetting.chat_integration_enabled? # Plugin may have been disabled since job triggered

        ::DiscourseChat::Manager.trigger_notifications(args[:post_id])
      end
    end
  end

  DiscourseEvent.on(:post_created) do |post| 
    if SiteSetting.chat_integration_enabled?
      # This will run for every post, even PMs. Don't worry, they're filtered out later.
      Jobs.enqueue_in(SiteSetting.chat_integration_delay_seconds.seconds,
          :notify_chats,
          post_id: post.id
        )
    end
  end

  class ::DiscourseChat::ChatController < ::ApplicationController
    requires_plugin DiscourseChat::PLUGIN_NAME

    def respond
      render
    end

    def list_providers
      providers = ::DiscourseChat::Provider.providers.map {|x| {name: x::PROVIDER_NAME, id: x::PROVIDER_NAME}}
      render json:providers, root: 'providers'
    end

    def list_rules
      providers = ::DiscourseChat::Provider.providers.map {|x| x::PROVIDER_NAME}

      requested_provider = params[:provider]

      if requested_provider.nil?
        rules = DiscourseChat::Rule.all
      elsif providers.include? requested_provider
        rules = DiscourseChat::Rule.all_for_provider(requested_provider)
      else
        raise Discourse::NotFound
      end

      render_serialized rules, DiscourseChat::RuleSerializer, root: 'rules'
    end

    def create_rule
      rule = DiscourseChat::Rule.new()
      hash = params.require(:rule)

      rule.update(hash)

      render_serialized rule, DiscourseChat::RuleSerializer, root: 'rule'
    end

    def update_rule
      rule = DiscourseChat::Rule.find(params[:id].to_i)
      hash = params.require(:rule)

      rule.update(hash)

      render_serialized rule, DiscourseChat::RuleSerializer, root: 'rule'
    end

    def destroy_rule
      rule = DiscourseChat::Rule.find(params[:id].to_i)

      rule.destroy

      render json: success_json
    end
  end

  class DiscourseChat::RuleSerializer < ActiveModel::Serializer
    attributes :id, :provider, :channel, :category_id, :tags, :filter
  end

  require_dependency 'admin_constraint'


  add_admin_route 'chat.menu_title', 'chat'

  DiscourseChat::Engine.routes.draw do
    get "" => "chat#respond"
    get '/providers' => "chat#list_providers"
    
    get '/rules' => "chat#list_rules"
    put '/rules' => "chat#create_rule"
    put '/rules/:id' => "chat#update_rule"
    delete '/rules/:id' => "chat#destroy_rule"

    get "/:provider" => "chat#respond"
  end

  Discourse::Application.routes.append do
    mount ::DiscourseChat::Engine, at: '/admin/plugins/chat', constraints: AdminConstraint.new
  end

end
