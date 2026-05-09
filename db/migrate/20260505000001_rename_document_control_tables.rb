class RenameDocumentControlTables < ActiveRecord::Migration[8.0]
  def change
    rename_table :document_control_doc_types, :doc_types
    rename_table :document_control_issues, :issues
    rename_table :document_control_source_formats, :source_formats
  end
end
