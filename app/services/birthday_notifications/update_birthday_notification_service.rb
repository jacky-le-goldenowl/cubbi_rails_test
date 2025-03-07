
module BirthdayNotifications
  class UpdateBirthdayNotificationService < ApplicationService
    include UserTimeHelper

    def initialize(user)
      @user = user
    end

    def call
      updated_today = today_local(user)
      updated_birthday = user.birthday_date.change(year: updated_today.year)
      notification = user.birthday_notifications&.scheduled&.first

      if notification.present? && notification.birthday != updated_birthday
        notification.update!(status: :cancelled)
      end
    end

    private

    attr_reader :user
  end
end
