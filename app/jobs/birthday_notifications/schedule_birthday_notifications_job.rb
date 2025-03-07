module BirthdayNotifications
  class ScheduleBirthdayNotificationsJob < ApplicationJob
    queue_as :default

    def perform
      service = BirthdayNotifications::BirthdayNotificationService.new()
      service.schedule_today_notifications
    end
  end
end
