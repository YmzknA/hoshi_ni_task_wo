class CreateMilestones < ActiveRecord::Migration[7.2]
  def change
    create_table :milestones do |t|
      t.string :title, null: false
      t.text :description
      t.integer :progress, null: false, default: 0
      t.boolean :is_public, null: false, default: false
      t.boolean :is_on_chart, null: false, default: true
      t.date :start_date
      t.date :end_date
      t.text :completed_comment

      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
