class CreateProjectChangeRequest < ActiveRecord::Migration[8.0]
  def change
    create_table :project_change_requests do |t|
      t.references :project, null: false
      t.integer :serial
      t.text :reason, null: false
      t.text :summary, null: false
      t.integer :duration, null: false
      t.timestamps
    end
    add_index :project_change_requests, [:project_id, :serial], unique: true
  end
end