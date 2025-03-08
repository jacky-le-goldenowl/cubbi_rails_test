module BirthdayNotifications
  module UserTimeHelper
    def birthday_today?(user)
      user.birthday_date.change(year: today_local(user).year) == today_local(user)
    end

    def today_local(user)
      @today_local ||= {}
      @today_local[user.id] ||= Time.current.in_time_zone(user_timezone(user)).to_date
    end

    def scheduled_time(user)
      Time.use_zone(user_timezone(user)) do
        Time.zone.local(
          today_local(user).year,
          user.birthday_date.month,
          user.birthday_date.day,
          BirthdayNotification::NOTIFICATION_TIME[:hour],
          BirthdayNotification::NOTIFICATION_TIME[:minute],
          0
        )
      end
    end

    def user_timezone(user)
      user.location.presence || "UTC"
    end
  end
end
