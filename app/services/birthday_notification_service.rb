
class BirthdayNotificationService < ApplicationService
  def self.schedule_today_notifications
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
            Sidekiq.logger.info "Created notification #{notification.id} for user #{user.id}"
          end

          if notification.scheduled? || (notification.errored? && notification.retry_count < BirthdayNotification::MAX_RETRIES)
            BirthdayNotificationJob.perform_at(scheduled_time, notification.id)
            Sidekiq.logger.info "Scheduled notification #{notification.id} at #{scheduled_time}"
          end
        end
      end
    end
  end

  def self.send_scheduled_notifications
    BirthdayNotification.where(status: :scheduled).find_each do |notification|
      BirthdayNotificationJob.perform_async(notification.id)
    end
  end

  def self.retry_failed_notifications
    BirthdayNotification.where(status: BirthdayNotification.statuses[:errored])
                         .where("retry_count < ?", BirthdayNotification::MAX_RETRIES)
                         .find_each do |notification|
      BirthdayNotificationJob.perform_async(notification.id)
    end
  end
end
