class MoveElectricalModelsToModule < ActiveRecord::Migration[8.0]
  def up
    # Remove foreign key constraints
    remove_foreign_key "cable_types", "projects"
    remove_foreign_key "cables", "cable_types"
    remove_foreign_key "circuits", "switchboards"
    
    # Remove indexes
    remove_index :cable_types, name: "index_cable_types_on_project_and_code"
    remove_index :cable_types, name: "index_cable_types_on_project_id"
    remove_index :cables, name: "index_cables_on_cable_type_id"
    remove_index :cables, name: "index_cables_on_from"
    remove_index :cables, name: "index_cables_on_to"
    remove_index :circuits, name: "index_circuits_on_switchboard_id_and_serial"
    remove_index :circuits, name: "index_circuits_on_switchboard_id"
    remove_index :demands, name: "index_demands_on_demandable"
    
    # Rename foreign key columns
    rename_column :cables, :cable_type_id, :electrical_cable_type_id
    rename_column :circuits, :switchboard_id, :electrical_switchboard_id
    rename_column :demands, :demandable_type, :demandable_type_old
    
    # Add new demandable_type with namespaced class names
    add_column :demands, :demandable_type, :string
    execute <<-SQL
      UPDATE demands 
      SET demandable_type = 'Electrical::' || demandable_type_old
    SQL
    remove_column :demands, :demandable_type_old
    
    # Rename tables
    rename_table :cable_types, :electrical_cable_types
    rename_table :cables, :electrical_cables
    rename_table :switchboards, :electrical_switchboards
    rename_table :circuits, :electrical_circuits
    rename_table :socket_ccts, :electrical_socket_ccts
    rename_table :light_ccts, :electrical_light_ccts
    rename_table :motors, :electrical_motors
    rename_table :demands, :electrical_demands
    
    # Recreate indexes with new column names
    add_index :electrical_cable_types, ["project_id", "code"], 
      name: "index_electrical_cable_types_on_project_and_code", 
      unique: true
    add_index :electrical_cable_types, ["project_id"], 
      name: "index_electrical_cable_types_on_project_id"
      
    add_index :electrical_cables, ["electrical_cable_type_id"], 
      name: "index_electrical_cables_on_electrical_cable_type_id"
    add_index :electrical_cables, ["from_type", "from_id"], 
      name: "index_electrical_cables_on_from"
    add_index :electrical_cables, ["to_type", "to_id"], 
      name: "index_electrical_cables_on_to"
      
    add_index :electrical_circuits, ["electrical_switchboard_id", "serial"], 
      name: "index_electrical_circuits_on_switchboard_id_and_serial", 
      unique: true
    add_index :electrical_circuits, ["electrical_switchboard_id"], 
      name: "index_electrical_circuits_on_electrical_switchboard_id"
      
    add_index :electrical_demands, ["demandable_type", "demandable_id"], 
      name: "index_electrical_demands_on_demandable"
    
    # Re-add foreign keys with new column names
    add_foreign_key "electrical_cable_types", "projects"
    add_foreign_key "electrical_cables", "electrical_cable_types"
    add_foreign_key "electrical_circuits", "electrical_switchboards"
  end

  def down
    # Remove foreign keys
    remove_foreign_key "electrical_cable_types", "projects"
    remove_foreign_key "electrical_cables", "electrical_cable_types"
    remove_foreign_key "electrical_circuits", "electrical_switchboards"
    
    # Remove indexes
    remove_index :electrical_cable_types, name: "index_electrical_cable_types_on_project_and_code"
    remove_index :electrical_cable_types, name: "index_electrical_cable_types_on_project_id"
    remove_index :electrical_cables, name: "index_electrical_cables_on_electrical_cable_type_id"
    remove_index :electrical_cables, name: "index_electrical_cables_on_from"
    remove_index :electrical_cables, name: "index_electrical_cables_on_to"
    remove_index :electrical_circuits, name: "index_electrical_circuits_on_switchboard_id_and_serial"
    remove_index :electrical_circuits, name: "index_electrical_circuits_on_electrical_switchboard_id"
    remove_index :electrical_demands, name: "index_electrical_demands_on_demandable"
    
    # Rename tables back
    rename_table :electrical_cable_types, :cable_types
    rename_table :electrical_cables, :cables
    rename_table :electrical_switchboards, :switchboards
    rename_table :electrical_circuits, :circuits
    rename_table :electrical_socket_circuits, :socket_ccts
    rename_table :electrical_light_circuits, :light_ccts
    rename_table :electrical_motors, :motors
    rename_table :electrical_demands, :demands
    
    # Revert column names
    rename_column :cables, :electrical_cable_type_id, :cable_type_id
    rename_column :circuits, :electrical_switchboard_id, :switchboard_id
    rename_column :demands, :demandable_type, :demandable_type_new
    
    # Revert demandable_type to original class names
    add_column :demands, :demandable_type, :string
    execute <<-SQL
      UPDATE demands 
      SET demandable_type = REPLACE(demandable_type_new, 'Electrical::', '')
      WHERE demandable_type_new LIKE 'Electrical::%'
    SQL
    remove_column :demands, :demandable_type_new
    
    # Recreate original indexes
    add_index :cable_types, ["project_id", "code"], 
      name: "index_cable_types_on_project_and_code", 
      unique: true
    add_index :cable_types, ["project_id"], 
      name: "index_cable_types_on_project_id"
      
    add_index :cables, ["cable_type_id"], 
      name: "index_cables_on_cable_type_id"
    add_index :cables, ["from_type", "from_id"], 
      name: "index_cables_on_from"
    add_index :cables, ["to_type", "to_id"], 
      name: "index_cables_on_to"
      
    add_index :circuits, ["switchboard_id", "serial"], 
      name: "index_circuits_on_switchboard_id_and_serial", 
      unique: true
    add_index :circuits, ["switchboard_id"], 
      name: "index_circuits_on_switchboard_id"
      
    add_index :demands, ["demandable_type", "demandable_id"], 
      name: "index_demands_on_demandable"
    
    # Re-add original foreign keys
    add_foreign_key "cable_types", "projects"
    add_foreign_key "cables", "cable_types"
    add_foreign_key "circuits", "switchboards"
  end
end