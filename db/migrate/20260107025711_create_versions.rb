# This migration creates the `versions` table for the Version class.
# All other migrations PT provides are optional.
class CreateVersions < ActiveRecord::Migration[8.0]

  # The largest text column available in all supported RDBMS is
  # 1024^3 - 1 bytes, roughly one gibibyte.  We specify a size
  # so that MySQL will use `longtext` instead of `text`.  Otherwise,
  # when serializing very large objects, `text` might not be big enough.
  TEXT_BYTES = 1_073_741_823

  def change
    create_table :versions do |t|
      # Consider using bigint type for performance if you are going to store only numeric ids.
      t.bigint   :whodunnit
      # t.string   :whodunnit

      t.datetime :created_at

      t.bigint   :item_id,   null: false
      t.string   :item_type, null: false
      t.string   :event,     null: false
      t.jsonb    :object # , limit: TEXT_BYTES

      # Custom metadata
      t.bigint   :project_id
      t.string   :ip
      t.string   :user_agent
    end
    add_index :versions, %i[item_type item_id]
    add_index :versions, :project_id
  end
end
