class CreateTasks < ActiveRecord::Migration[7.2]
  def change
    create_table :tasks do |t|
      t.string :title, null: false
      t.text :description
      t.integer :progress, null: false, default: 0
      t.date :start_date
      t.date :end_date

      t.references :milestone, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
