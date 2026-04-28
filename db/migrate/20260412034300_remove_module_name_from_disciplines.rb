class RemoveModuleNameFromDisciplines < ActiveRecord::Migration[8.0]
  def change
    remove_column :disciplines, :module_name, :string
  end
end
