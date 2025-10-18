class AddNotesToLightCcts < ActiveRecord::Migration[8.0]
  def change
    add_column :light_ccts, :notes, :text
  end
end
