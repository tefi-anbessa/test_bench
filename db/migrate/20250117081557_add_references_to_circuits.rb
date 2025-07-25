class AddReferencesToCircuits < ActiveRecord::Migration[7.0]
  def change
    add_reference :circuits, :load, foreign_key: true
    add_reference :circuits, :cable, foreign_key: true
  end
end
