class RenameLoadsToDemands < ActiveRecord::Migration[7.0]
  def up
    # Rename the table
    rename_table :loads, :demands
    
    # Rename the polymorphic columns
    rename_column :demands, :loadable_id, :demandable_id
    rename_column :demands, :loadable_type, :demandable_type
    
    # Update polymorphic type column for demandable associations
    execute "UPDATE demands SET demandable_type = 'Demand' WHERE demandable_type = 'Load'"
    
    # Update the foreign key in the circuits table
    if column_exists?(:circuits, :load_id)
      remove_foreign_key :circuits, column: :load_id
      rename_column :circuits, :load_id, :demand_id
      add_foreign_key :circuits, :demands, column: :demand_id
    end
    
    # Update index names
    if index_name_exists?(:demands, 'index_loads_on_loadable')
      remove_index :demands, name: 'index_loads_on_loadable'
      add_index :demands, [:demandable_type, :demandable_id], name: 'index_demands_on_demandable'
    end
    
    # Update any other indexes
    if index_name_exists?(:demands, 'index_loads_on_circuit_id')
      rename_index :demands, 'index_loads_on_circuit_id', 'index_demands_on_circuit_id'
    end
  end

  def down
    # Revert index names first
    if index_name_exists?(:demands, 'index_demands_on_demandable')
      remove_index :demands, name: 'index_demands_on_demandable'
      add_index :demands, [:demandable_type, :demandable_id], name: 'index_loads_on_loadable'
    end
    
    if index_name_exists?(:demands, 'index_demands_on_circuit_id')
      rename_index :demands, 'index_demands_on_circuit_id', 'index_loads_on_circuit_id'
    end
    
    # Revert the foreign key in the circuits table
    if column_exists?(:circuits, :demand_id)
      remove_foreign_key :circuits, column: :demand_id
      rename_column :circuits, :demand_id, :load_id
      add_foreign_key :circuits, :demands, column: :load_id
    end
    
    # Revert polymorphic type column
    execute "UPDATE demands SET demandable_type = 'Load' WHERE demandable_type = 'Demand'"
    
    # Revert column names
    rename_column :demands, :demandable_id, :loadable_id
    rename_column :demands, :demandable_type, :loadable_type
    
    # Rename the table back
    rename_table :demands, :loads
  end
end
