class MakeDisciplineSwatchNullable < ActiveRecord::Migration[8.0]
  def change
    change_column_null :disciplines, :swatch_id, true
  end
end
