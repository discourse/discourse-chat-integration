# frozen_string_literal: true

class DiscourseChat::ChatController < ApplicationController
  requires_plugin DiscourseChat::PLUGIN_NAME

  def respond
    render
  end

  def list_providers
    providers = ::DiscourseChat::Provider.enabled_providers.map do |x|
      {
        name: x::PROVIDER_NAME,
        id: x::PROVIDER_NAME,
        channel_parameters: (defined? x::CHANNEL_PARAMETERS) ? x::CHANNEL_PARAMETERS : []
      }
    end

    render json: providers, root: 'providers'
  end

  def test
    begin
      channel_id = params[:channel_id].to_i
      topic_id = params[:topic_id].to_i

      channel = DiscourseChat::Channel.find(channel_id)

      provider = ::DiscourseChat::Provider.get_by_name(channel.provider)

      if !DiscourseChat::Provider.is_enabled(provider)
        raise Discourse::NotFound
      end

      post = Topic.find(topic_id.to_i).posts.first

      provider.trigger_notification(post, channel, nil)

      render json: success_json
    rescue Discourse::InvalidParameters, ActiveRecord::RecordNotFound => e
      render json: { errors: [e.message] }, status: 422
    rescue DiscourseChat::ProviderError => e
      Rails.logger.error("Test provider failed #{e.info}")
      if e.info.key?(:error_key) && !e.info[:error_key].nil?
        render json: { error_key: e.info[:error_key] }, status: 422
      else
        render json: { errors: [e.message] }, status: 422
      end
    end
  end

  def list_channels
    providers = ::DiscourseChat::Provider.enabled_provider_names
    requested_provider = params[:provider]

    raise Discourse::InvalidParameters if !providers.include?(requested_provider)

    channels = DiscourseChat::Channel.with_provider(requested_provider)
    render_serialized channels, DiscourseChat::ChannelSerializer, root: 'channels'
  end

  def create_channel
    begin
      providers = ::DiscourseChat::Provider.enabled_providers.map { |x| x::PROVIDER_NAME }

      if !defined?(params[:channel]) && defined?(params[:channel][:provider])
        raise Discourse::InvalidParameters, 'Provider is not valid'
      end

      requested_provider = params[:channel][:provider]

      if !providers.include?(requested_provider)
        raise Discourse::InvalidParameters, 'Provider is not valid'
      end

      allowed_keys = DiscourseChat::Provider.get_by_name(requested_provider)::CHANNEL_PARAMETERS.map { |p| p[:key].to_sym }

      hash = params.require(:channel).permit(:provider, data: allowed_keys)

      channel = DiscourseChat::Channel.new(hash)

      if !channel.save
        raise Discourse::InvalidParameters, 'Channel is not valid'
      end

      render_serialized channel, DiscourseChat::ChannelSerializer, root: 'channel'
    rescue Discourse::InvalidParameters => e
      render json: { errors: [e.message] }, status: 422
    end
  end

  def update_channel
    begin
      channel = DiscourseChat::Channel.find(params[:id].to_i)
      channel.error_key = nil # Reset any error on the rule

      allowed_keys = DiscourseChat::Provider.get_by_name(channel.provider)::CHANNEL_PARAMETERS.map { |p| p[:key].to_sym }

      hash = params.require(:channel).permit(data: allowed_keys)

      if !channel.update(hash)
        raise Discourse::InvalidParameters, 'Channel is not valid'
      end

      render_serialized channel, DiscourseChat::ChannelSerializer, root: 'channel'
    rescue Discourse::InvalidParameters => e
      render json: { errors: [e.message] }, status: 422
    end
  end

  def destroy_channel
    rule = DiscourseChat::Channel.find_by(id: params[:id])
    raise Discourse::InvalidParameters unless rule
    rule.destroy!

    render json: success_json
  end

  def create_rule
    begin
      hash = params.require(:rule).permit(:channel_id, :type, :filter, :group_id, :category_id, tags: [])
      rule = DiscourseChat::Rule.new(hash)

      if !rule.save
        raise Discourse::InvalidParameters, 'Rule is not valid'
      end

      render_serialized rule, DiscourseChat::RuleSerializer, root: 'rule'
    rescue Discourse::InvalidParameters => e
      render json: { errors: [e.message] }, status: 422
    end
  end

  def update_rule
    begin
      rule = DiscourseChat::Rule.find(params[:id].to_i)
      hash = params.require(:rule).permit(:type, :filter, :group_id, :category_id, tags: [])

      if !rule.update(hash)
        raise Discourse::InvalidParameters, 'Rule is not valid'
      end

      render_serialized rule, DiscourseChat::RuleSerializer, root: 'rule'
    rescue Discourse::InvalidParameters => e
      render json: { errors: [e.message] }, status: 422
    end
  end

  def destroy_rule
    rule = DiscourseChat::Rule.find_by(id: params[:id])
    raise Discourse::InvalidParameters.new unless rule
    rule.destroy!

    render json: success_json
  end
end
