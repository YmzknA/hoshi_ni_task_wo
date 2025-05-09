class AddUserIdToLimitedSharingTask < ActiveRecord::Migration[7.2]
  def change
    add_reference :limited_sharing_tasks, :user, null: false, foreign_key: true
  end
end
