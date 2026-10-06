class CreateInstrumentPressureTransmitter < ActiveRecord::Migration[8.0]
  def change
    create_table :instrument_pressure_transmitters do |t|
      t.integer :measurement_type, null: false
      t.integer :pressure_unit
      t.float :range_min, null: false
      t.float :range_max, null: false
      t.integer :signal
      t.integer :communication
      t.integer :fluid_phase
      t.integer :process_fluid
      t.integer :accuracy_class
      t.integer :connection_type
      t.integer :connection_size
      t.integer :case_material
      t.integer :wetted_material
      t.integer :movement_type
      t.string :ip_rating
      t.jsonb :accessories
      t.text :notes
      t.timestamps
    end
  end
end