
class AddCoresToCableTypes < ActiveRecord::Migration[8.0]
  def up
    # Store the original column types for rollback
    conductor_material_type = column_type(:cable_types, :conductor_material)
    insulation_type = column_type(:cable_types, :insulation)
    bedding_type = column_type(:cable_types, :bedding)
    armour_type = column_type(:cable_types, :armour)
    sheath_type = column_type(:cable_types, :sheath)

    # Remove the old conductor_makeup column if it exists
    remove_column :cable_types, :conductor_makeup, :string if column_exists?(:cable_types, :conductor_makeup)
    
    # Rename the description column to notes if it exists
    rename_column :cable_types, :description, :notes if column_exists?(:cable_types, :description)
    
    # Add new columns
    add_column :cable_types, :cores, :integer
    add_column :cable_types, :voltage_rating, :integer

    # Convert string columns to enums
    change_column :cable_types, :conductor_material, :integer
    change_column :cable_types, :insulation, :integer
    change_column :cable_types, :bedding, :integer
    change_column :cable_types, :armour, :integer
    change_column :cable_types, :sheath, :integer

    # Handle the code column
    if column_exists?(:cable_types, :unique_spec)
      remove_index :cable_types, :unique_spec if index_exists?(:cable_types, :unique_spec)
      rename_column :cable_types, :unique_spec, :code
      
      # Only add the index if it doesn't already exist
      index_name = "index_cable_types_on_project_and_code"
      unless index_exists?(:cable_types, [:project_id, :code], name: index_name)
        add_index :cable_types, [:project_id, :code], 
          unique: true, 
          name: index_name
      end
    end

    # Update all cable types with new codes and default values
    CableType.reset_column_information
    CableType.find_each do |cable_type|
      # Set default values for new columns if they're nil
      cable_type.cores ||= 1
      cable_type.voltage_rating ||= 0
      
      # Always regenerate the code to ensure consistency with the new format
      cable_type.send(:generate_code)
      
      # Save without validation to handle any missing required fields
      cable_type.save!(validate: false, touch: false)
    end
  end

  def down
    # Store the current column types
    conductor_material_type = column_type(:cable_types, :conductor_material)
    insulation_type = column_type(:cable_types, :insulation)
    bedding_type = column_type(:cable_types, :bedding)
    armour_type = column_type(:cable_types, :armour)
    sheath_type = column_type(:cable_types, :sheath)

    # Revert column type changes
    change_column :cable_types, :conductor_material, :string
    change_column :cable_types, :insulation, :string
    change_column :cable_types, :bedding, :string
    change_column :cable_types, :armour, :string
    change_column :cable_types, :sheath, :string

    # Revert code column back to unique_spec if it was renamed
    if column_exists?(:cable_types, :code)
      remove_index :cable_types, :code if index_exists?(:cable_types, :code)
      rename_column :cable_types, :code, :unique_spec
      add_index :cable_types, :unique_spec, unique: true
    end

    # Rename the description column to notes if it exists
    rename_column :cable_types, :notes, :description if column_exists?(:cable_types, :notes)
    
    # Remove added columns
    remove_column :cable_types, :cores
    remove_column :cable_types, :voltage_rating

    # Re-add conductor_makeup column if it was removed
    unless column_exists?(:cable_types, :conductor_makeup)
      add_column :cable_types, :conductor_makeup, :string
    end
  end

  private

  def column_type(table_name, column_name)
    ActiveRecord::Base.connection.columns(table_name).find { |c| c.name == column_name.to_s }&.type
  end
end