class AddIsOnChartToLimitedSharingMilestones < ActiveRecord::Migration[7.2]
  def change
    add_column :limited_sharing_milestones, :is_on_chart, :boolean, default: false, null: false
  end
end
