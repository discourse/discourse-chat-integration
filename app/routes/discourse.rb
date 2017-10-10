Discourse::Application.routes.append do
  mount ::DiscourseChat::AdminEngine, at: '/admin/plugins/chat', constraints: AdminConstraint.new
  mount ::DiscourseChat::PublicEngine, at: '/chat-transcript/', as: 'chat-transcript'
  mount ::DiscourseChat::Provider::HookEngine, at: '/chat-integration/'

  # For backwards compatibility with Slack plugin
  post "/slack/command" => "discourse_chat/provider/slack_provider/slack_command#command"
end
