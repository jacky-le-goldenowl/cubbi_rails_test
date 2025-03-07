class User < ApplicationRecord
  # Associations
  has_many :birthday_notifications

  # Validations
  validates_uniqueness_of :email
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :birthday_date, presence: true

  # Calbacks
  after_update :update_birthday_notification, if: :saved_change_to_birthday_date?

  private

  def update_birthday_notification
    BirthdayNotifications::UpdateBirthdayNotificationService.call(self)
  end
end
