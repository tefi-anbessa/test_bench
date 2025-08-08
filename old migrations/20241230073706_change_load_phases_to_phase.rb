class ChangeLoadPhasesToPhase < ActiveRecord::Migration[7.0]
  def change
    rename_column :loads, :phases, :phase
  end
end
