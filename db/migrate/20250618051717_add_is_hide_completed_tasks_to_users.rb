class AddIsHideCompletedTasksToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :is_hide_completed_tasks, :boolean, default: false, null: false
  end
end
