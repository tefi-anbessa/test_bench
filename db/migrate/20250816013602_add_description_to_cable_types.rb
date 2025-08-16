class AddDescriptionToCableTypes < ActiveRecord::Migration[7.0]
  def up
    add_column :cable_types, :description, :text, null: false, default: ''
    
    # Update existing records with generated descriptions
    CableType.reset_column_information
    CableType.find_each do |cable_type|
      cable_type.update_columns(description: cable_type.description)
    end
  end
  
  def down
    remove_column :cable_types, :description
  end
end
