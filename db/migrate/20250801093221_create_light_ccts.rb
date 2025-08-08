class CreateLightCcts < ActiveRecord::Migration[7.0]
  def change
    create_table :light_ccts do |t|
      t.string :light_fitting_type
      t.integer :quantity

      t.timestamps
    end
  end
end
