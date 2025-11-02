class AddPrefixSchemaToDisciplines < ActiveRecord::Migration[8.0]
  def change
    add_column :disciplines, :prefix_schema, :jsonb
  end
end
