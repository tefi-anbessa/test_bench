class AddUniqueIndexToCableTypes < ActiveRecord::Migration[7.0]
  def up
    if ActiveRecord::Base.connection.adapter_name.downcase.include?('sqlite')
      # SQLite-compatible version
      add_column :cable_types, :unique_spec, :string, as: %q{
        COALESCE(conductor_material, '') || '|' ||
        COALESCE(conductor_makeup, '') || '|' ||
        COALESCE(csa, '') || '|' ||
        COALESCE(insulation, '') || '|' ||
        COALESCE(bedding, '') || '|' ||
        COALESCE(armour, '') || '|' ||
        COALESCE(sheath, '') || '|' ||
        COALESCE(temperature_rating, '') || '|' ||
        COALESCE(neutral_csa, '') || '|' ||
        COALESCE(earth_csa, '') || '|' ||
        COALESCE(bedding_od, '') || '|' ||
        COALESCE(overall_od, '')
      }, stored: true

      add_index :cable_types, :unique_spec, unique: true, name: 'index_cable_types_on_unique_spec'
    else
      # PostgreSQL/MySQL version
      execute <<-SQL
        ALTER TABLE cable_types
        ADD COLUMN unique_spec text GENERATED ALWAYS AS (
          COALESCE(conductor_material, '') || '|' ||
          COALESCE(conductor_makeup, '') || '|' ||
          COALESCE(csa::text, '') || '|' ||
          COALESCE(insulation, '') || '|' ||
          COALESCE(bedding, '') || '|' ||
          COALESCE(armour, '') || '|' ||
          COALESCE(sheath, '') || '|' ||
          COALESCE(temperature_rating::text, '') || '|' ||
          COALESCE(neutral_csa::text, '') || '|' ||
          COALESCE(earth_csa::text, '') || '|' ||
          COALESCE(bedding_od::text, '') || '|' ||
          COALESCE(overall_od::text, '')
        ) STORED;

        CREATE UNIQUE INDEX index_cable_types_on_unique_spec ON cable_types(unique_spec);
      SQL
    end
  end

  def down
    remove_index :cable_types, :unique_spec if index_exists?(:cable_types, :unique_spec)
    remove_column :cable_types, :unique_spec if column_exists?(:cable_types, :unique_spec)
  end
end
