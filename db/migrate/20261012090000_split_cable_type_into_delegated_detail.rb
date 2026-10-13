class SplitCableTypeIntoDelegatedDetail < ActiveRecord::Migration[8.0]
  def up
    # New shared base table for CableType. detail_type/detail_id is the
    # delegated_type pointer (see app/models/cable_type.rb), same shape as
    # Tag's own tagable_type/tagable_id.
    create_table :cable_types do |t|
      t.bigint :discipline_id, null: false
      t.string :code
      t.string :spec_summary
      t.text :notes, default: "", null: false
      t.integer :primary_role, null: false
      t.integer :construction
      t.integer :groups
      t.integer :conductor_material
      t.float :csa
      t.integer :insulation
      t.integer :bedding
      t.integer :armour
      t.integer :sheath
      t.decimal :bedding_od, precision: 3, scale: 1
      t.decimal :overall_od, precision: 3, scale: 1
      t.integer :temperature_rating
      t.integer :voltage_rating
      t.integer :fire_protection
      t.jsonb :environment_protection
      t.jsonb :applicable_standard
      t.string :detail_type
      t.bigint :detail_id
      t.timestamps
    end
    add_index :cable_types, :discipline_id
    add_index :cable_types, [:detail_type, :detail_id]
    add_foreign_key :cable_types, :disciplines

    create_table :electrical_cable_type_details do |t|
      t.float :neutral_csa
      t.float :earth_csa
      t.timestamps
    end

    create_table :instrument_cable_type_details do |t|
      t.boolean :individual_screen, default: false, null: false
      t.boolean :overall_screen, default: false, null: false
      t.float :twist_pitch
      t.timestamps
    end

    # Migrate existing data. The new cable_types row keeps the SAME id as
    # the old electrical_cable_types row it came from, so cables.cable_type_id
    # (currently pointing at electrical_cable_types) needs no remapping -
    # only the polymorphic cable_type_type column needs to go.
    execute <<-SQL
      INSERT INTO electrical_cable_type_details (id, neutral_csa, earth_csa, created_at, updated_at)
      SELECT id, neutral_csa, earth_csa, created_at, updated_at FROM electrical_cable_types
    SQL

    execute <<-SQL
      INSERT INTO cable_types (
        id, discipline_id, code, spec_summary, notes, primary_role, construction, groups,
        conductor_material, csa, insulation, bedding, armour, sheath, bedding_od, overall_od,
        temperature_rating, voltage_rating, detail_type, detail_id, created_at, updated_at
      )
      SELECT
        id, discipline_id, code, code, notes,
        0, -- primary_role: existing rows predate the field - default to power_distribution,
           -- the only role Electrical::CableType was ever used for until now.
        construction, groups, conductor_material, csa, insulation, bedding, armour, sheath,
        bedding_od, overall_od, temperature_rating, voltage_rating,
        'Electrical::CableTypeDetail', id, created_at, updated_at
      FROM electrical_cable_types
    SQL

    # Keep both tables' id sequences past whatever was just inserted explicitly.
    execute "SELECT setval(pg_get_serial_sequence('cable_types', 'id'), COALESCE((SELECT MAX(id) FROM cable_types), 1))"
    execute "SELECT setval(pg_get_serial_sequence('electrical_cable_type_details', 'id'), COALESCE((SELECT MAX(id) FROM electrical_cable_type_details), 1))"

    remove_foreign_key :electrical_cable_types, :disciplines
    drop_table :electrical_cable_types

    # Cable's own cable_type association is no longer polymorphic - CableType
    # is one shared class now, so a plain FK replaces the type/id pair.
    remove_index :cables, name: "index_cables_on_cable_type"
    remove_column :cables, :cable_type_type
    add_foreign_key :cables, :cable_types
    add_index :cables, :cable_type_id
  end

  def down
    remove_foreign_key :cables, :cable_types
    remove_index :cables, :cable_type_id
    add_column :cables, :cable_type_type, :string
    execute "UPDATE cables SET cable_type_type = 'Electrical::CableType'"
    change_column_null :cables, :cable_type_type, false
    add_index :cables, [:cable_type_type, :cable_type_id], name: "index_cables_on_cable_type"

    create_table :electrical_cable_types do |t|
      t.integer :conductor_material
      t.float :csa
      t.float :neutral_csa
      t.float :earth_csa
      t.integer :insulation
      t.integer :bedding
      t.integer :armour
      t.integer :sheath
      t.decimal :bedding_od, precision: 3, scale: 1
      t.decimal :overall_od, precision: 3, scale: 1
      t.integer :temperature_rating
      t.string :code
      t.text :notes, default: "", null: false
      t.integer :groups
      t.integer :voltage_rating
      t.integer :construction
      t.bigint :discipline_id, null: false
      t.timestamps
    end
    add_index :electrical_cable_types, :discipline_id
    add_foreign_key :electrical_cable_types, :disciplines

    execute <<-SQL
      INSERT INTO electrical_cable_types (
        id, discipline_id, code, notes, construction, groups, conductor_material, csa,
        neutral_csa, earth_csa, insulation, bedding, armour, sheath, bedding_od, overall_od,
        temperature_rating, voltage_rating, created_at, updated_at
      )
      SELECT
        ct.id, ct.discipline_id, ct.code, ct.notes, ct.construction, ct.groups, ct.conductor_material, ct.csa,
        d.neutral_csa, d.earth_csa, ct.insulation, ct.bedding, ct.armour, ct.sheath, ct.bedding_od, ct.overall_od,
        ct.temperature_rating, ct.voltage_rating, ct.created_at, ct.updated_at
      FROM cable_types ct
      LEFT JOIN electrical_cable_type_details d ON d.id = ct.detail_id AND ct.detail_type = 'Electrical::CableTypeDetail'
    SQL

    execute "SELECT setval(pg_get_serial_sequence('electrical_cable_types', 'id'), COALESCE((SELECT MAX(id) FROM electrical_cable_types), 1))"

    drop_table :instrument_cable_type_details
    drop_table :electrical_cable_type_details
    remove_foreign_key :cable_types, :disciplines
    drop_table :cable_types
  end
end
