class RenameDocTypeNameToLabel < ActiveRecord::Migration[8.0]
  def change
    rename_column :document_control_doc_types, :name, :label
  end
end
