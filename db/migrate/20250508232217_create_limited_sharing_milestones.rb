class CreateLimitedSharingMilestones < ActiveRecord::Migration[7.2]
  def change
    create_table :limited_sharing_milestones, id: :string, limit: 21 do |t|
      t.string :title, null: false
      t.text :description
      t.integer :progress, default: 0, null: false
      t.string :color, default: "#FFDF5E", null: false
      t.date :start_date
      t.date :end_date
      t.text :completed_comment

      t.references :user, null: false, foreign_key: true
      t.references :constellation, foreign_key: true

      t.timestamps
    end
  end
end
