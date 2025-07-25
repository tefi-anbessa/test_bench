class AddColumnsToCircuits < ActiveRecord::Migration[7.0]
  def change
    add_column :circuits, :phase, :integer
    add_column :circuits, :contactor?, :boolean
  end
end
