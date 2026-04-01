class CreateDocumentControlSourceFormat < ActiveRecord::Migration[8.0]
  def change
    create_table :document_control_source_formats do |t|
      t.string :name, null: false
      t.string :file_extension
      t.string :revision, null: true
      t.text :notes
      t.index [:revision, :name], unique: true
      t.timestamps
    end
  end
end