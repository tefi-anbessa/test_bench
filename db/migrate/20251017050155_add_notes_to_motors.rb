class AddNotesToMotors < ActiveRecord::Migration[8.0]
  def change
    add_column :motors, :notes, :text
  end
end
