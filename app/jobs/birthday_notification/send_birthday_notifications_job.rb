class SendBirthdayNotificationsJob
  include Sidekiq::Job

  def perform
    BirthdayNotificationService.send_scheduled_notifications
  end
end
