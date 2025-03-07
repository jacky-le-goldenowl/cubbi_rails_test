class BirthdayNotification < ApplicationRecord
  MAX_RETRIES = 3

  belongs_to :user

  enum :status, { scheduled: 0, sent: 1, errored: 2  }

  validates :birthday, uniqueness: { scope: :user_id, message: "Notification for this birthday already exists." }
  validates :retry_count, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: MAX_RETRIES }
end
