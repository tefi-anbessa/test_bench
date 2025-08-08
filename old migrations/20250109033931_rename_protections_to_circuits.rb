class RenameProtectionsToCircuits < ActiveRecord::Migration[7.0]
  def change
    rename_table :protections, :circuits
  end
end
