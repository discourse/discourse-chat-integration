class DiscourseChat::ChatController < ApplicationController
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
      rules = DiscourseChat::Rule.with_provider(requested_provider)
    else
      raise Discourse::NotFound
    end

    render_serialized rules, DiscourseChat::RuleSerializer, root: 'rules'
  end

  def create_rule
    begin
      hash = params.require(:rule).permit(:provider, :channel, :filter, :category_id, tags:[])

      rule = DiscourseChat::Rule.new(hash)
      
      if not rule.save(hash)
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
      hash = params.require(:rule).permit(:provider, :channel, :filter, :category_id, tags:[])
      
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