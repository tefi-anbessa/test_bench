class RemoveLocationFromSwitchboards < ActiveRecord::Migration[8.0]
  def change
    remove_column :switchboards, :location, :string
  end
end
