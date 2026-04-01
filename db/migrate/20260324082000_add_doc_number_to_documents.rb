class AddDocNumberToDocuments < ActiveRecord::Migration[8.0]
  def change
    add_column :documents, :doc_number, :string
    add_index :documents, :doc_number, unique: true
  end
end
