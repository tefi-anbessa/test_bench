class CreateElectricalHeater < ActiveRecord::Migration[8.0]
  def change
    create_table :electrical_heaters do |t|
      t.integer :heater_type, null: false
      t.integer :application, null: false
      t.string :ingress_protection
      t.float :sheath_temperature_max
      t.float :power_density_min
      t.float :power_density_max
      t.integer :sheath_material
      t.integer :insulation_material

      t.timestamps
    end

  end
end