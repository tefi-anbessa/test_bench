class AddRequiredRoleToDiscipline < ActiveRecord::Migration[8.0]
  def change
    add_column :disciplines, :required_role, :string
  end
end
