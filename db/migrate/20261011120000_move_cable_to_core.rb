class MoveCableToCore < ActiveRecord::Migration[8.0]
  def up
    # Remove the foreign key and index tied to the single-class association -
    # cable_type becomes polymorphic below, so a DB-level FK no longer
    # applies (same as the existing from/to polymorphic columns on this
    # table, which never had one).
    remove_foreign_key "electrical_cables", "electrical_cable_types"
    remove_index :electrical_cables, name: "index_electrical_cables_on_electrical_cable_type_id"

    rename_table :electrical_cables, :cables
    rename_index :cables, "index_electrical_cables_on_from", "index_cables_on_from"
    rename_index :cables, "index_electrical_cables_on_to", "index_cables_on_to"

    add_column :cables, :cable_type_type, :string
    add_column :cables, :cable_type_id, :integer

    # Backfill from the still-present old column before it's dropped -
    # every existing cable today references Electrical::CableType.
    execute <<-SQL
      UPDATE cables
      SET cable_type_type = 'Electrical::CableType',
          cable_type_id = electrical_cable_type_id
    SQL

    change_column_null :cables, :cable_type_type, false
    change_column_null :cables, :cable_type_id, false

    remove_column :cables, :electrical_cable_type_id
    add_index :cables, [:cable_type_type, :cable_type_id], name: "index_cables_on_cable_type"
  end

  def down
    add_column :cables, :electrical_cable_type_id, :integer

    execute <<-SQL
      UPDATE cables
      SET electrical_cable_type_id = cable_type_id
      WHERE cable_type_type = 'Electrical::CableType'
    SQL

    change_column_null :cables, :electrical_cable_type_id, false
    remove_index :cables, name: "index_cables_on_cable_type"
    remove_column :cables, :cable_type_id
    remove_column :cables, :cable_type_type

    rename_index :cables, "index_cables_on_from", "index_electrical_cables_on_from"
    rename_index :cables, "index_cables_on_to", "index_electrical_cables_on_to"
    rename_table :cables, :electrical_cables

    add_index :electrical_cables, ["electrical_cable_type_id"], name: "index_electrical_cables_on_electrical_cable_type_id"
    add_foreign_key "electrical_cables", "electrical_cable_types"
  end
end
