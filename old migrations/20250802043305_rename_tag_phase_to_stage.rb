class RenameTagPhaseToStage < ActiveRecord::Migration[7.0]
  def change
    rename_column :tags, :phase, :stage
  end
end
