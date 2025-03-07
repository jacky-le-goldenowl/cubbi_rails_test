class SetDefaultsForBirthdayNotifications < ActiveRecord::Migration[8.0]
  def change
    change_column_default :birthday_notifications, :status, from: nil, to: 0
    change_column_default :birthday_notifications, :retry_count, from: nil, to: 0
  end
end
