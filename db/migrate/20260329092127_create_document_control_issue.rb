class CreateDocumentControlIssue < ActiveRecord::Migration[8.0]
  def change
    create_table :document_control_issues do |t|
      t.references :document, null: false
      t.string :code, null: false
      t.string :reason, null: false
      t.references :document_control_source_format, foreign_key: true
      t.timestamps
    end
    add_index :document_control_issues, [:document_id, :code], unique: true
  end
end