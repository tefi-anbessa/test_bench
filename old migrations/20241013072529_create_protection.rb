class CreateProtection < ActiveRecord::Migration[7.0]
  def change
    create_table :protections do |t|
      t.references :load, null: false, foreign_key: true
      t.integer :device
      t.integer :poles
      t.integer :curve
      t.float :rating
      t.integer :elcb
      t.text :notes

      t.timestamps
    end
  end
end
