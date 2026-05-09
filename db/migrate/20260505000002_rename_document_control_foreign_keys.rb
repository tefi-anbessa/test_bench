class RenameDocumentControlForeignKeys < ActiveRecord::Migration[8.0]
  def change
    # Rename foreign key in issues table
    rename_column :issues, :document_control_source_format_id, :source_format_id
  end
end
