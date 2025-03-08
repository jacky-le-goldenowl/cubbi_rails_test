
module BirthdayNotifications
  class SendScheduledNotificationService < ApplicationService
    def call
      BirthdayNotification.where(status: :scheduled).find_each do |notification|
        SendBirthdayNotificationJob.perform_later(notification.id)
      end
    end
  end
end
