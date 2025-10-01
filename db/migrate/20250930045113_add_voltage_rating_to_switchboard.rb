class AddVoltageRatingToSwitchboard < ActiveRecord::Migration[8.0]
  def change
    add_column :switchboards, :voltage_rating, :integer
  end
end
