module BirthdayNotifications
  class ScheduleTodayNotificationService < ApplicationService
    include UserTimeHelper

    def call
      User.find_each do |user|
        next unless birthday_today?(user)

        notification = BirthdayNotification.find_or_initialize_by(
          user: user,
          birthday: today_local(user)
        )

        next unless notification.save! && should_schedule?(notification)

        SendBirthdayNotificationJob.set(wait_until: scheduled_time(user))
                                   .perform_later(notification.id)
      end
    end

    private

    def should_schedule?(notification)
      notification.scheduled? ||
        (notification.failed? && notification.retry_count < BirthdayNotification::MAX_RETRIES)
    end
  end
end
