class BirthdayNotificationJob
  include Sidekiq::Job

  def perform(notification_id)
    notification = BirthdayNotification.find(notification_id)
    user = notification.user

    message = "Hey, #{user.first_name} #{user.last_name} it’s your birthday"

    response = HookbinRequestService.send_post_request(message: message)

    if response.is_a?(Net::HTTPSuccess)
      notification.update(status: :sent)
    else
      notification.increment!(:retry_count)
      if notification.retry_count < BirthdayNotification::MAX_RETRIES
        notification.update(status: BirthdayNotification.statuses[:errored])
      else
        Rails.logger.error(
          "RETRY LIMIT EXCEEDED: Notification #{notification.id} failed after #{BirthdayNotification::MAX_RETRIES} retries"
        )
      end
    end
  rescue => e
    Rails.logger.error("###ERROR!!!: Error sending notification #{notification_id}: #{e.message}")
    notification.increment!(:retry_count) if notification.present?
    notification.update(status: BirthdayNotification.statuses[:errored]) if notification.present?
  end
end
