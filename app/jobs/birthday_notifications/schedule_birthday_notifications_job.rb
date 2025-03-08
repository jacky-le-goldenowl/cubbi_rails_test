module BirthdayNotifications
  class ScheduleBirthdayNotificationsJob < ApplicationJob
    queue_as :default

    def perform
      BirthdayNotifications::ScheduleTodayNotificationService.call()
    end
  end
end
