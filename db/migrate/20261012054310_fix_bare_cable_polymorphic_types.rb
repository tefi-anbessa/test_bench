class FixBareCablePolymorphicTypes < ActiveRecord::Migration[8.0]
  def up
    execute <<-SQL
      UPDATE cables SET from_type = 'Electrical::' || from_type
      WHERE from_type IS NOT NULL AND from_type NOT LIKE '%::%'
    SQL
    execute <<-SQL
      UPDATE cables SET to_type = 'Electrical::' || to_type
      WHERE to_type IS NOT NULL AND to_type NOT LIKE '%::%'
    SQL
  end

  def down
    execute <<-SQL
      UPDATE cables SET from_type = REPLACE(from_type, 'Electrical::', '')
      WHERE from_type LIKE 'Electrical::%'
    SQL
    execute <<-SQL
      UPDATE cables SET to_type = REPLACE(to_type, 'Electrical::', '')
      WHERE to_type LIKE 'Electrical::%'
    SQL
  end
end
