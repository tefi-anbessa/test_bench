class AddNotesToSwitchboards < ActiveRecord::Migration[8.0]
  def change
    add_column :switchboards, :notes, :text
  end
end
