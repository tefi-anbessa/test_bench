class AddTagToLoads < ActiveRecord::Migration[7.0]
  def change
    add_reference :loads, :tag, null: false, foreign_key: true
  end
end
