class AddSwatchReferenceToDiscipline < ActiveRecord::Migration[8.0]
  def change
    add_reference :disciplines, :swatch, null: true, foreign_key: true
    
    # Set all existing disciplines to reference the default swatch (id = 1)
    execute 'UPDATE disciplines SET swatch_id = 1 WHERE swatch_id IS NULL'
    
    # Now make the column not nullable
    change_column_null :disciplines, :swatch_id, false
  end
end
