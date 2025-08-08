class CreateSocketCcts < ActiveRecord::Migration[7.0]
  def change
    create_table :socket_ccts do |t|
      t.string :socket_type
      t.integer :quantity

      t.timestamps
    end
  end
end
