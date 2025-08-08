class CreateLoads < ActiveRecord::Migration[7.0]
  def change
    create_table :loads do |t|
      t.integer :circuit
      t.integer :basis
      t.string :basis_notes
      t.float :supply
      t.integer :phase
      t.float :power
      t.float :vector
      t.float :power_factor
      t.float :current
      t.float :duty

      t.timestamps
    end
  end
end
