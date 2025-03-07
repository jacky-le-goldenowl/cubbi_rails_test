class BirthdayNotificationJob < ApplicationJob
  queue_as :default

  retry_on StandardError, wait: 5.seconds, attempts: BirthdayNotification::MAX_RETRIES

  after_perform do |job|
    notification_id = job.arguments.first
    notification = BirthdayNotification.find_by(id: notification_id)

    notification.update(status: :sent) if notification.present?
  end

  rescue_from(StandardError) do |exception, job|
    notification_id = (job || self).arguments.first
    notification = BirthdayNotification.find_by(id: notification_id)
    handle_notification_failure(notification, exception) if notification.present?
    raise exception
  end

  def perform(notification_id)
    notification = BirthdayNotification.find_by(id: notification_id)
    unless notification
      Rails.logger.error("Notification with id #{notification_id} not found. Exiting job.")
      return
    end

    user = notification.user
    message = "Hey, #{user.first_name} #{user.last_name}, it's your birthday!"
    response = HookbinRequestService.call({ message: message })

    unless response.is_a?(Net::HTTPSuccess)
      raise StandardError, "Failed to send notification #{notification.id}"
    end
  end

  private

  def handle_notification_failure(notification, exception)
    notification.increment!(:retry_count)
    notification.update(status: BirthdayNotification.statuses[:failed])
  end
end
