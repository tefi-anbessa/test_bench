class RemoveCircuitFromLoad < ActiveRecord::Migration[7.0]
  def change
    remove_index :loads, :name =>"index_loads_on_circuit_and_loadable"
    remove_column :loads, :circuit, :integer
  end
end
