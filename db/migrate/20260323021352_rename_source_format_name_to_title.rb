class RenameSourceFormatNameToTitle < ActiveRecord::Migration[8.0]
  def change
    rename_column :document_control_source_formats, :name, :title
  end
end
