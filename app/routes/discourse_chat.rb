require_dependency 'admin_constraint'

module DiscourseChat
  AdminEngine.routes.draw do
    get "" => "chat#respond"
    get '/providers' => "chat#list_providers"
    post '/test' => "chat#test_provider"
    
    get '/rules' => "chat#list_rules"
    put '/rules' => "chat#create_rule"
    put '/rules/:id' => "chat#update_rule"
    delete '/rules/:id' => "chat#destroy_rule"

    get "/:provider" => "chat#respond"
  end
end