class AddUniqueIndexOnDisciplineName < ActiveRecord::Migration[8.0]
  def up
    add_index :disciplines, [:project_id, :name], unique: true, name: "index_disciplines_on_project_id_and_name"
  end

  def down
    remove_index :disciplines, name: "index_disciplines_on_project_id_and_name"
  end
end
