module BirthdayNotifications
  class SendBirthdayNotificationsJob < ApplicationJob
    queue_as :default

    def perform
      service = BirthdayNotifications::BirthdayNotificationService.new()
      service.send_scheduled_notifications
    end
  end
end
