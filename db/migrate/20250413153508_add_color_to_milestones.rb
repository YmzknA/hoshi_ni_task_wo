class AddColorToMilestones < ActiveRecord::Migration[7.2]
  def change
    add_column :milestones, :color, :string, default: "#FFDF5E", null: false

    reversible do |dir|
      dir.up do
        Milestone.update_all(color: "#FFDF5E")
      end
    end
  end
end
