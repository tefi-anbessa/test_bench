class AddCatalogRequiredRoleToDiscipline < ActiveRecord::Migration[8.0]
  def change
    add_column :disciplines, :catalog_required_role, :string
    add_index :disciplines, :catalog_required_role
    add_index :disciplines, :required_role
  end
end
