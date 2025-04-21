class CreateConstellations < ActiveRecord::Migration[7.2]
  def change
    create_table :constellations do |t|
      t.string :name, null: false
      t.integer :number_of_stars, null: false

      t.timestamps
    end
  end
end
