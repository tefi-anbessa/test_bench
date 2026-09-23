module Electrical
  module HeaterExtension

    private

      # Only allow a list of trusted parameters through.
      def tagable_params
        params.require(:electrical_heater).permit(:heater_type, :application, :ingress_protection,
          :sheath_temperature_max, :power_density_min, :power_density_max,
          :sheath_material, :insulation_material, :notes)
      end
  end
end
