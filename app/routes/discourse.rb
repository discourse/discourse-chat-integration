Discourse::Application.routes.append do
  mount ::DiscourseChat::AdminEngine, at: '/admin/plugins/chat', constraints: AdminConstraint.new
  mount ::DiscourseChat::Provider::HookEngine, at: '/chat-integration/'
end