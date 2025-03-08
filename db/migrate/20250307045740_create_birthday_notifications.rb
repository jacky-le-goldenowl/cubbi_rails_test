class CreateBirthdayNotifications < ActiveRecord::Migration[8.0]
  def change
    create_table :birthday_notifications do |t|
      t.integer :status
      t.date :birthday
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end

    add_index :birthday_notifications, [ :user_id, :birthday ], unique: true, name: 'index_birthday_notifications_on_user_id_and_birthday'
  end
end
