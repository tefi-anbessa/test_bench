class AddNotesToCables < ActiveRecord::Migration[8.0]
  def change
    add_column :cables, :notes, :text
  end
end
