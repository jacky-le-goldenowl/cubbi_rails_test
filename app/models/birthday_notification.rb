class BirthdayNotification < ApplicationRecord
  # Constants
  MAX_RETRIES = 2
  NOTIFICATION_TIME = { hour: 9, minute: 0 }.freeze # TODO: Move to config or Settings or ENV

  # Associations
  belongs_to :user

  # Enums
  enum :status, { scheduled: 0, sent: 1, failed: 2, cancelled: 3 }

  # Validations
  validates :birthday, uniqueness: { scope: :user_id, message: "Notification for this birthday already exists." }
  validates :retry_count, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: MAX_RETRIES + 1 }
end
