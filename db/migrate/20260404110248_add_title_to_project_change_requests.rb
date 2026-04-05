class AddTitleToProjectChangeRequests < ActiveRecord::Migration[8.0]
  def change
    add_column :project_change_requests, :title, :string, null: false
    add_index :project_change_requests, [:title, :project_id], unique: true
  end
end
