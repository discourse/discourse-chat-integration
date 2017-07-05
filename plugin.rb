# name: discourse-chat-integration
# about: This plugin integrates discourse with a number of chat providers
# version: 0.1
# url: https://github.com/discourse/discourse-chat-integration

enabled_site_setting :chat_integration_enabled

register_asset "stylesheets/chat-integration-admin.scss"

# Site setting validators must be loaded before initialize
require_relative "lib/validators/chat_integration_slack_enabled_setting_validator"

after_initialize do

  module ::DiscourseChat
    PLUGIN_NAME = "discourse-chat-integration".freeze

    class AdminEngine < ::Rails::Engine
      engine_name DiscourseChat::PLUGIN_NAME+"-admin"
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
  require_relative "lib/discourse_chat/helper"

  module ::Jobs
    class NotifyChats < Jobs::Base
      sidekiq_options retry: false # Don't retry, could result in duplicate notifications for some providers
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
      providers = ::DiscourseChat::Provider.enabled_providers.map {|x| {
                                        name: x::PROVIDER_NAME, 
                                        id: x::PROVIDER_NAME, 
                                        channel_regex: (defined? x::PROVIDER_CHANNEL_REGEX) ? x::PROVIDER_CHANNEL_REGEX : nil
                                        }}
      
      render json:providers, root: 'providers'
    end

    def test_provider
      begin
        requested_provider = params[:provider]
        channel = params[:channel]
        topic_id = params[:topic_id]

        provider = ::DiscourseChat::Provider.get_by_name(requested_provider)

        if provider.nil? or not ::DiscourseChat::Provider.is_enabled(provider)
          raise Discourse::NotFound
        end

        if defined? provider::PROVIDER_CHANNEL_REGEX
          channel_regex = Regexp.new provider::PROVIDER_CHANNEL_REGEX
          raise Discourse::InvalidParameters, 'Channel is not valid' if not channel_regex.match?(channel)
        end

        post = Topic.find(topic_id.to_i).posts.first

        provider.trigger_notification(post, channel)

        render json:success_json
      rescue Discourse::InvalidParameters, ActiveRecord::RecordNotFound => e
        render json: {errors: [e.message]}, status: 422
      rescue DiscourseChat::ProviderError => e
        if e.info.key?(:error_key) and !e.info[:error_key].nil?
          render json: {error_key: e.info[:error_key]}, status: 422
        else 
          render json: {errors: [e.message]}, status: 422
        end
      end
    end

    def list_rules
      providers = ::DiscourseChat::Provider.enabled_providers.map {|x| x::PROVIDER_NAME}

      requested_provider = params[:provider]

      if providers.include? requested_provider
        rules = DiscourseChat::Rule.all_for_provider(requested_provider)
      else
        raise Discourse::NotFound
      end

      render_serialized rules, DiscourseChat::RuleSerializer, root: 'rules'
    end

    def create_rule
      begin
        rule = DiscourseChat::Rule.new()
        hash = params.require(:rule)

        if not rule.update(hash)
          raise Discourse::InvalidParameters, 'Rule is not valid'
        end

        render_serialized rule, DiscourseChat::RuleSerializer, root: 'rule'
      rescue Discourse::InvalidParameters => e
        render json: {errors: [e.message]}, status: 422
      end
    end

    def update_rule
      begin
        rule = DiscourseChat::Rule.find(params[:id].to_i)
        rule.error_key = nil # Reset any error on the rule
        hash = params.require(:rule)

        if not rule.update(hash)
          raise Discourse::InvalidParameters, 'Rule is not valid'
        end

        render_serialized rule, DiscourseChat::RuleSerializer, root: 'rule'
      rescue Discourse::InvalidParameters => e
        render json: {errors: [e.message]}, status: 422
      end
    end

    def destroy_rule
      rule = DiscourseChat::Rule.find(params[:id].to_i)

      rule.destroy

      render json: success_json
    end
  end

  class DiscourseChat::RuleSerializer < ActiveModel::Serializer
    attributes :id, :provider, :channel, :category_id, :tags, :filter, :error_key
  end

  require_dependency 'admin_constraint'


  add_admin_route 'chat_integration.menu_title', 'chat'

  DiscourseChat::AdminEngine.routes.draw do
    get "" => "chat#respond"
    get '/providers' => "chat#list_providers"
    post '/test' => "chat#test_provider"
    
    get '/rules' => "chat#list_rules"
    put '/rules' => "chat#create_rule"
    put '/rules/:id' => "chat#update_rule"
    delete '/rules/:id' => "chat#destroy_rule"

    get "/:provider" => "chat#respond"
  end

  Discourse::Application.routes.append do
    mount ::DiscourseChat::AdminEngine, at: '/admin/plugins/chat', constraints: AdminConstraint.new
    mount ::DiscourseChat::Provider::HookEngine, at: '/chat-integration/'
  end

  DiscourseChat::Provider.mount_engines

end
