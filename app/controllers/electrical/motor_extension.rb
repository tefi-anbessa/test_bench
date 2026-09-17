module Electrical
  module MotorExtension

    private

      # Only allow a list of trusted parameters through.
      def tagable_params
        params.require(:electrical_motor).permit(:motor_type, :frame_size, :poles,
          :ingress_protection, :speed_rated, :notes)
      end
  end
end
