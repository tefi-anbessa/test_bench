class AddNotesToSocketCcts < ActiveRecord::Migration[8.0]
  def change
    add_column :socket_ccts, :notes, :text
  end
end
