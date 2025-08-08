class CreateCables < ActiveRecord::Migration[7.0]
  def change
    create_table :cables do |t|
      t.references :cable_type, null: false, foreign_key: true
      t.references :circuit, foreign_key: true
#       t.references :load, foreign_key: true
      t.decimal :route_length, precision: 4, scale: 1
      t.decimal :vertical_allowance, precision: 3, scale: 1
      t.decimal :termination_allowance, precision: 3, scale: 1
      t.integer :start_mark
      t.integer :end_mark

      t.timestamps
    end
  end
end
