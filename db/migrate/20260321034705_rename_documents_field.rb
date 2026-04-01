class RenameDocumentsField < ActiveRecord::Migration[8.0]
  def change
    rename_column :documents, :document_control_doc_type_id, :doc_type_id
  end
end
