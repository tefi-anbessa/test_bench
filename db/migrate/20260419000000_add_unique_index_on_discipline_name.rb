class AddUniqueIndexOnDisciplineName < ActiveRecord::Migration[8.0]
  def up
    unless index_exists?(:disciplines, [:project_id, :name], name: "index_disciplines_on_project_id_and_name")
      add_index :disciplines, [:project_id, :name], unique: true, name: "index_disciplines_on_project_id_and_name"
    end
  end

  def down
    remove_index :disciplines, name: "index_disciplines_on_project_id_and_name" if index_exists?(:disciplines, [:project_id, :name], name: "index_disciplines_on_project_id_and_name")
  end
end
