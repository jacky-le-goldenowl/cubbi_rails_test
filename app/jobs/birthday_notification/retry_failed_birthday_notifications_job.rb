module BirthdayNotification
  class RetryFailedBirthdayNotificationsJob
    include Sidekiq::Job

    def perform
      BirthdayNotificationService.retry_failed_notifications
    end
  end
end
