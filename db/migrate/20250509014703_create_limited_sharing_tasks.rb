class CreateLimitedSharingTasks < ActiveRecord::Migration[7.2]
  def change
    create_table :limited_sharing_tasks, id: :string, limit: 21 do |t|
      t.string :title, null: false
      t.text :description
      t.integer :progress, default: 0, null: false
      t.date :start_date
      t.date :end_date
      t.references :limited_sharing_milestone, type: :string, foreign_key: true, null: false
      t.timestamps
    end
  end
end
