class RenameDocTypeLabelToName < ActiveRecord::Migration[8.0]
  def change
    rename_column :doc_types, :label, :name
  end
end
