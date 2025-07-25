class ChangeLoadPhaseToConfiguration < ActiveRecord::Migration[7.0]
  def change
    rename_column :loads, :phase, :config
  end
end
