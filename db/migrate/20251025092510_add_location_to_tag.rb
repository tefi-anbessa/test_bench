class AddLocationToTag < ActiveRecord::Migration[8.0]
  def change
    add_column :tags, :location, :string
  end
end
