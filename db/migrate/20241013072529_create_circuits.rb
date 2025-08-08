class CreateCircuits < ActiveRecord::Migration[7.0]
  def change
    create_table :circuits do |t|
      t.references :switchboard, null: false, foreign_key: true
      t.integer :serial
      t.integer :phase
      t.integer :device
      t.integer :poles
      t.integer :curve
      t.float :rating
      t.integer :elcb
      t.boolean :contactor
      t.text :notes
      t.index [:switchboard_id, :serial], unique: true

      t.timestamps
    end
  end
end
