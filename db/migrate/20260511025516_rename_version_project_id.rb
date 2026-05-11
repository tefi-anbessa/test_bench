class RenameVersionProjectId < ActiveRecord::Migration[8.0]
  def change
    rename_column :versions, :project_id, :current_project_id
  end
end
