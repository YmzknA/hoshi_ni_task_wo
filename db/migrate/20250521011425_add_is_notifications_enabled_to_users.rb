class AddIsNotificationsEnabledToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :is_notifications_enabled, :boolean, default: false, null: false
  end
end
