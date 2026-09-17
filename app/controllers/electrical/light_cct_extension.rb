module Electrical
  module LightCctExtension

    private

      # Only allow a list of trusted parameters through.
      def tagable_params
        params.require(:electrical_light_cct).permit(:light_fitting_type, :quantity, :notes)
      end
  end
end
