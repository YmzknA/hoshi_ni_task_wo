class AddConstellationToMilestones < ActiveRecord::Migration[7.2]
  def change
    add_reference :milestones, :constellation, foreign_key: true
  end
end
