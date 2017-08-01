class DiscourseChat::PublicController < ApplicationController
  requires_plugin DiscourseChat::PLUGIN_NAME

  def post_transcript
    params.require(:secret)

    redis_key = "chat_integration:transcript:" + params[:secret]
    content = $redis.get(redis_key)

    if content
      render json: { content: content }
      return
    end

    raise Discourse::NotFound

  end
end
