class CreateDocumentControlDocType < ActiveRecord::Migration[8.0]
  def change
    create_table :document_control_doc_types do |t|
      t.references :discipline, foreign_key: true
      t.string :code, null: false
      t.string :name, null: false
      t.text :description
      t.index [:discipline_id, :code], unique: true
      t.timestamps
    end
  end
end