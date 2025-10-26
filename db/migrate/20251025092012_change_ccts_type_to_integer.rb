class ChangeCctsTypeToInteger < ActiveRecord::Migration[8.0]
  def change
    change_column :socket_ccts, :socket_type, :integer
    change_column :light_ccts, :light_fitting_type, :integer
  end
end
