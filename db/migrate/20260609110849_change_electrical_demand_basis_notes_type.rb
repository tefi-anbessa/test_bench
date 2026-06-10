class ChangeElectricalDemandBasisNotesType < ActiveRecord::Migration[8.0]
  def change
    change_column :electrical_demands, :basis_notes, :text
  end
end
