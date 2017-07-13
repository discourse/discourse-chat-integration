module Jobs
  class NotifyChats < Jobs::Base
    sidekiq_options retry: false # Don't retry, could result in duplicate notifications for some providers
    def execute(args)
      return if not SiteSetting.chat_integration_enabled? # Plugin may have been disabled since job triggered

      ::DiscourseChat::Manager.trigger_notifications(args[:post_id])
    end
  end
end