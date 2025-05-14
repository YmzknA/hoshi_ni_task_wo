class AddIsOpenToMilestones < ActiveRecord::Migration[7.2]
  def change
    add_column :milestones, :is_open, :boolean, default: true, null: false
  end
end
