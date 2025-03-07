module BirthdayNotification
  class ScheduleBirthdayNotificationsJob
    include Sidekiq::Job

    def perform
      BirthdayNotificationService.schedule_today_notifications
    end
  end
end
