class RenameIpRatingToIngressProtectionOnInstrumentModels < ActiveRecord::Migration[8.0]
  def change
    rename_column :instrument_pressure_gauges, :ip_rating, :ingress_protection
    rename_column :instrument_pressure_transmitters, :ip_rating, :ingress_protection
  end
end
