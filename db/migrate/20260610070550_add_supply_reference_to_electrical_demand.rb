class AddSupplyReferenceToElectricalDemand < ActiveRecord::Migration[8.0]
  def change
    add_column :electrical_demands, :supply_reference, :integer
  end
end
