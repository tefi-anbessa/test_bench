class CreateCableTypes < ActiveRecord::Migration[7.0]
  def change
    create_table :cable_types do |t|
      t.string :conductor_material
      t.string :conductor_makeup
      t.float :csa
      t.float :neutral_csa
      t.float :earth_csa
      t.string :insulation
      t.string :bedding
      t.string :armour
      t.string :sheath
      t.decimal :bedding_od, precision: 3, scale: 1
      t.decimal :overall_od, precision: 3, scale: 1
      t.integer :temperature_rating

      t.timestamps
    end
  end
end
