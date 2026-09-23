module Electrical
  module SwitchboardExtension

    private

      def setup_additional_form_data
        @circuits = @switchboard.persisted? ? @switchboard.circuits.count : 0
        @voltage_ratings = Constants.electrical.voltage_ratings
      end

      def after_create_hook(switchboard)
        circuits_count = params.dig(:electrical_switchboard, :circuits).presence || params[:circuits].presence
        update_circuits(switchboard, circuits_count.to_i) if circuits_count
      end

      def after_update_hook(switchboard)
        circuits_count = params.dig(:electrical_switchboard, :circuits).presence || params[:circuits].presence
        update_circuits(switchboard, circuits_count.to_i) if circuits_count
      end

      # Updates the number of circuits for the switchboard
      def update_circuits(switchboard, desired_count = nil)
        return unless desired_count && desired_count > 0

        current_count = switchboard.circuits.count
        count = desired_count - current_count
        if count > 0
          authorize switchboard, :create?
          
          count.times do |i|
            switchboard.circuits.create(serial: current_count + i + 1)
          end
          resource_name = Electrical::Circuit.model_name.human(count: count)
          flash[:success] << t("flash.assigned", count: count, resource_name: resource_name)
        elsif count < 0
          authorize switchboard, :destroy?
          switchboard.circuits
                    .order(serial: :desc)
                    .limit(current_count - desired_count)
                    .destroy_all
          resource_name = Electrical::Circuit.model_name.human(count: count*-1)
          flash[:success] << t("flash.destroyed", count: count*-1, resource_name: resource_name)
        end
      end

      # Only allow a list of trusted parameters through.
      def tagable_params
        params.require(:electrical_switchboard).permit(:ingress_protection, :voltage_rating,
          :busbar_rating, :busbar_fault_rating, :busbar_fault_duration, 
          :cable_entry, :incomer_protection, :metering, 
          :neutral_bar_connections, :earth_bar_connections, :notes
          )
      end
  end
end