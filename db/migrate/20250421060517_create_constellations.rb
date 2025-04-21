class CreateConstellations < ActiveRecord::Migration[7.2]
  def change
    create_table :constellations do |t|
      t.timestamps
    end
  end
end
