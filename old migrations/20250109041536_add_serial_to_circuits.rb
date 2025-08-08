class AddSerialToCircuits < ActiveRecord::Migration[7.0]
  def change
    add_column :circuits, :serial, :integer
  end
end
