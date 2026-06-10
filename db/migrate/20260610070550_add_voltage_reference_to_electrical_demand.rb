class AddVoltageReferenceToElectricalDemand < ActiveRecord::Migration[8.0]
  def change
    add_column :electrical_demands, :voltage_reference, :integer
  end
end
