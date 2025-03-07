class BirthdayNotificationJob < ApplicationJob
  queue_as :default

  retry_on StandardError, wait: 5.seconds, attempts: BirthdayNotification::MAX_RETRIES

  after_perform do |job|
    notification_id = arguments.first
    notification = BirthdayNotification.find_by(id: notification_id)
    notification.update(status: :sent) if notification.present?
  end

  rescue_from(StandardError) do |exception|
    notification_id = arguments.first
    notification = BirthdayNotification.find_by(id: notification_id)
    notification.increment!(:retry_count) if notification.present?
    notification.update(status: BirthdayNotification.statuses[:failed]) if notification.present?
    raise exception
  end

  def perform(notification_id)
    notification = BirthdayNotification.find(notification_id)
    user = notification.user

    message = "Hey, #{user.first_name} #{user.last_name} it’s your birthday"

    response = HookbinRequestService.new({ message: message }).call

    unless response.is_a?(Net::HTTPSuccess)
      raise StandardError, "Failed to send notification #{notification.id}"
    end
  end
end
