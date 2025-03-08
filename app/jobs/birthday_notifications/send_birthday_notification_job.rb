module BirthdayNotifications
  class SendBirthdayNotificationJob < ApplicationJob
    queue_as :default

    retry_on StandardError, wait: 5.seconds, attempts: BirthdayNotification::MAX_RETRIES

    after_perform do |job|
      update_notification_status((job || self).arguments.first, :sent)
    end

    rescue_from(StandardError) do |exception, job|
      update_notification_status((job || self).arguments.first, :failed, exception)
      raise exception
    end

    def perform(notification_id)
      notification = BirthdayNotification.find_by(id: notification_id)
      return log_error("Notification with id #{notification_id} not found. Exiting job.") if notification.blank? || notification.sent?

      user = notification.user
      message = "Hey, #{user.first_name} #{user.last_name}, it's your birthday!"
      response = HookbinRequestService.call({ message: message })

      raise StandardError, "Failed to send notification #{notification.id}" unless response.is_a?(Net::HTTPSuccess)
    end

    private

    def update_notification_status(notification_id, status, exception = nil)
      notification = BirthdayNotification.find_by(id: notification_id)
      return unless notification

      if status == :failed
        notification.increment!(:retry_count)
        log_error("Notification #{notification_id} failed: #{exception.message}") if exception
      end

      notification.update(status: status)
    end

    def log_error(message)
      Rails.logger.error(message)
    end
  end
end
