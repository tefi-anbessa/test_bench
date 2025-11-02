class RemoveCircuitReferenceFromCables < ActiveRecord::Migration[7.0]
  def change
    # Remove the foreign key constraint
    remove_foreign_key :cables, :circuits if foreign_key_exists?(:cables, :circuits)

    # Remove the index by its name
    remove_index :cables, name: "index_cables_on_circuit_id" if index_exists?(:cables, "index_cables_on_circuit_id")

    # Remove the circuit_id column
    remove_column :cables, :circuit_id, :integer
  end
end