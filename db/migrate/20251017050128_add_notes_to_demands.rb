class AddNotesToDemands < ActiveRecord::Migration[8.0]
  def change
    add_column :demands, :notes, :text
  end
end
