module BirthdayNotifications
  class SendScheduledBirthdayNotificationsJob < ApplicationJob
    queue_as :default

    def perform
      BirthdayNotifications::SendScheduledNotificationService.call()
    end
  end
end
