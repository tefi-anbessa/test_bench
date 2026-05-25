class AddParentToTag < ActiveRecord::Migration[8.0]
  def change
    add_reference :tags, :parent, null: true, foreign_key: { to_table: :tags }
  end
end
