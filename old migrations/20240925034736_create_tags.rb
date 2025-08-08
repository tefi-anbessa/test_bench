class CreateTags < ActiveRecord::Migration[7.0]
  def change
    create_table :tags do |t|
      t.string :prefix
      t.integer :serial
      t.string :suffix, default: ""
      t.string :description
      t.text :notes
      t.references :project, null: false, foreign_key: true
      t.integer :phase
      t.references :discipline, null: false, foreign_key: true

      t.timestamps
    end

  end
end
