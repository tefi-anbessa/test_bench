class RenameCircuitsLoadToSwitchboard < ActiveRecord::Migration[7.0]
  def change
    rename_column :circuits, :load_id, :switchboard_id
  end
end
