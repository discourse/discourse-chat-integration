module DiscourseChat::Provider::TelegramProvider
  class TelegramCommandController < DiscourseChat::Provider::HookController
    requires_provider ::DiscourseChat::Provider::TelegramProvider::PROVIDER_NAME

    def say_hello

    	render json: {hello: "from telegram"}
    end
  end

  class TelegramEngine < ::Rails::Engine
    engine_name DiscourseChat::PLUGIN_NAME+"-telegram"
    isolate_namespace DiscourseChat::Provider::TelegramProvider
  end

  TelegramEngine.routes.draw do
  	get "command" => "telegram_command#say_hello"
  end
end