class RemoveCircuitIdIndexFromDemand < ActiveRecord::Migration[8.0]
  def change
    # Remove the index first
    remove_index :demands, :circuit_id if index_exists?(:demands, :circuit_id)
    
    # Remove the column
    remove_column :demands, :circuit_id, :integer
  end
end
