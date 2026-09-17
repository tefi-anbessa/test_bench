module Electrical
  module SocketCctExtension

    private

      # Only allow a list of trusted parameters through.
      def tagable_params
        params.require(:electrical_socket_cct).permit(:socket_type, :quantity, :notes)
      end
  end
end
