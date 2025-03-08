class AddRetryCountToBirthdayNotification < ActiveRecord::Migration[8.0]
  def change
    add_column :birthday_notifications, :retry_count, :integer
  end
end
