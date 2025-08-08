class CreateSwitchboards < ActiveRecord::Migration[7.0]
  def change
    create_table :switchboards do |t|
      t.string :location
      t.integer :service
      t.string :ingress_protection
      t.float :busbar_rating
      t.float :busbar_fault_rating
      t.float :busbar_fault_duration
      t.string :cable_entry
      t.text :incomer_protection
      t.text :metering
      t.text :neutral_bar_connections
      t.text :earth_bar_connections

      t.timestamps
    end
  end
end
