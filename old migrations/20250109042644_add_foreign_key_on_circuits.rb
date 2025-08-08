class AddForeignKeyOnCircuits < ActiveRecord::Migration[7.0]
  def change
    add_foreign_key :circuits, :switchboards, column: :switchboard_id 
  end
end
