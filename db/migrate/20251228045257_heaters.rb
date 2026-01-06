class Heaters < ActiveRecord::Migration[8.0]
  def change
    add_column :electrical_heaters, :notes, :text
  end
end
