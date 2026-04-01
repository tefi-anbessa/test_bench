class CreateDocument < ActiveRecord::Migration[8.0]
  def change
    create_table :documents do |t|
      t.references :discipline, foreign_key: true
      t.references :document_control_doc_type, foreign_key: true
      t.integer :serial
      t.string :title, null: false
      t.text :notes
      t.index [:serial, :discipline_id, :document_control_doc_type_id], unique: true
      t.timestamps
    end
  end
end