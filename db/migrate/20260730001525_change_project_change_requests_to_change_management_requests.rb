class ChangeProjectChangeRequestsToChangeManagementRequests < ActiveRecord::Migration[8.0]
  def change
    rename_table :project_change_requests, :change_management_requests
  end
end
