# frozen_string_literal: true

module DiscourseChatIntegration
  class ProviderError < StandardError
    attr_accessor :info

    def initialize(message = nil, info: nil)
      super(message)
      self.info = info.nil? ? {} : info
    end
  end

  module Provider
    def self.providers
      constants.select do |constant|
        constant.to_s =~ /Provider$/
      end.map(&method(:const_get))
    end

    def self.enabled_providers
      self.providers.select do |provider|
        self.is_enabled(provider)
      end
    end

    def self.provider_names
      self.providers.map! { |x| x::PROVIDER_NAME }
    end

    def self.enabled_provider_names
      self.enabled_providers.map! { |x| x::PROVIDER_NAME }
    end

    def self.get_by_name(name)
      self.providers.find { |p| p::PROVIDER_NAME == name }
    end

    def self.is_enabled(provider)
      if defined? provider::PROVIDER_ENABLED_SETTING
        SiteSetting.public_send(provider::PROVIDER_ENABLED_SETTING)
      else
        false
      end
    end

    class HookEngine < ::Rails::Engine
      engine_name DiscourseChatIntegration::PLUGIN_NAME + "-hooks"
      isolate_namespace DiscourseChatIntegration::Provider
    end

    class HookController < ::ApplicationController
      requires_plugin DiscourseChatIntegration::PLUGIN_NAME

      class ProviderDisabled < StandardError; end

      rescue_from ProviderDisabled  do
        rescue_discourse_actions(:not_found, 404)
      end

      def self.requires_provider(provider_name)
        before_action do
          raise ProviderDisabled.new unless Provider.enabled_provider_names.include?(provider_name)
        end
      end

      def respond
        render
      end
    end

    # Automatically mount each provider's engine inside the HookEngine
    def self.mount_engines
      engines = []
      DiscourseChatIntegration::Provider.providers.each do |provider|
        engine = provider.constants.select do |constant|
          constant.to_s =~ (/Engine$/) && (constant.to_s != "HookEngine")
        end.map(&provider.method(:const_get)).first

        if engine
          engines.push(engine: engine, name: provider::PROVIDER_NAME)
        end
      end

      DiscourseChatIntegration::Provider::HookEngine.routes.draw do
        engines.each do |engine|
          mount engine[:engine], at: engine[:name]
        end
      end
    end

  end
end

require_relative "provider/slack/slack_provider"
require_relative "provider/telegram/telegram_provider"
require_relative "provider/discord/discord_provider"
require_relative "provider/mattermost/mattermost_provider"
require_relative "provider/matrix/matrix_provider"
require_relative "provider/zulip/zulip_provider"
require_relative "provider/rocketchat/rocketchat_provider"
require_relative "provider/gitter/gitter_provider"
require_relative "provider/flowdock/flowdock_provider"
require_relative "provider/groupme/groupme_provider"
require_relative "provider/teams/teams_provider"
require_relative "provider/webex/webex_provider"
require_relative "provider/google/google_provider"
require_relative "provider/guilded/guilded_provider"
