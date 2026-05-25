class RenameDisciplineLabelToCode < ActiveRecord::Migration[8.0]
  def change
    rename_column :disciplines, :label, :code
  end
end
