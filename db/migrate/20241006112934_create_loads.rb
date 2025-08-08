class CreateLoads < ActiveRecord::Migration[7.0]
  def change
    create_table :loads do |t|
#       t.references :tag, null: false, foreign_key: true
      t.references :loadable, polymorphic: true, null: false, index: true
      t.references :circuit, foreign_key: true
      t.integer :basis
      t.string :basis_notes
      t.float :supply
      t.integer :config
      t.float :power
      t.float :vector
      t.float :power_factor
      t.float :current
      t.float :duty

      t.timestamps
    end
  end
end
