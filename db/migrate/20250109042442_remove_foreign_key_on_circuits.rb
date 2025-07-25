class RemoveForeignKeyOnCircuits < ActiveRecord::Migration[7.0]
  def change
    remove_foreign_key :circuits, :loads, column: :switchboard_id
  end
end
