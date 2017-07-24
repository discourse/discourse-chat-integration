Discourse::Application.routes.append do
  mount ::DiscourseChat::AdminEngine, at: '/admin/plugins/chat', constraints: AdminConstraint.new
  mount ::DiscourseChat::PublicEngine, at: '/chat-transcript/', as: 'chat-transcript'
  mount ::DiscourseChat::Provider::HookEngine, at: '/chat-integration/'
end