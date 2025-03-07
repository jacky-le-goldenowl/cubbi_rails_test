class User < ApplicationRecord
  has_many :birthday_notifications

  validates_uniqueness_of :email

  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
end
