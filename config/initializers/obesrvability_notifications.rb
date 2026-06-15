Rails.application.config.after_initialize do
  ActiveSupport::Notifications.subscribe(
    "process_action.action_controller",
    Subscribers::Observability::ApiRequestSubscriber
  )
end
