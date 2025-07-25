class AddTagableToTags < ActiveRecord::Migration[7.0]
  def change
    add_reference :tags, :tagable, polymorphic: true, null: true, index: true
  end
end
