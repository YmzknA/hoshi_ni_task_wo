class CreateConstallations < ActiveRecord::Migration[7.2]
  def change
    create_table :constallations do |t|
      t.string :name, null: false
      num_of_stars :integer, null: false

      t.timestamps
    end
  end
end
