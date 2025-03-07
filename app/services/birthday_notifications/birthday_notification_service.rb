
module BirthdayNotifications
  class BirthdayNotificationService < ApplicationService
    def schedule_today_notifications
      User.find_each do |user|
        user_tz = user.location.presence || "UTC"

        today_local = Time.current.in_time_zone(user_tz).to_date

        user_birthday = user.birthday_date.change(year: today_local.year)

        if user_birthday == today_local
          scheduled_time = Time.use_zone(user_tz) { Time.zone.local(today_local.year, user_birthday.month, user_birthday.day, 9, 0, 0) }

          BirthdayNotification.transaction do
            notification = BirthdayNotification.find_or_initialize_by(
              user: user,
              birthday: user_birthday
            )
            if notification.new_record?
              notification.status = :scheduled
              notification.retry_count = 0
              notification.save!
            end

            if notification.scheduled? || (notification.failed? && notification.retry_count < BirthdayNotification::MAX_RETRIES)
              BirthdayNotificationJob.set(wait_until: scheduled_time).perform_later(notification.id)
            end
          end
        end
      end
    end

    def send_scheduled_notifications
      BirthdayNotification.where(status: :scheduled).find_each do |notification|
        BirthdayNotificationJob.perform_later(notification.id)
      end
    end
  end
end
