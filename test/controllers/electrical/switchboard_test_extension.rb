module Electrical
  module SwitchboardTestExtension

    
      # Set the expected params for a valid resource
      def create_params
        { electrical_switchboard:
          {
            voltage_rating: '600/1000V',
            busbar_rating: '600A',
            busbar_fault_rating: 2000.0,
            busbar_fault_duration: 0.5,
            cable_entry: 'Bottom',
            incomer_protection: 'Isolator 4P',
            metering: 'None',
            neutral_bar_connections: 'None',
            earth_bar_connections: 'None',
            ingress_protection: '20',
            notes: 'Test switchboard'
          }
        }
      end

      def after_create_hook(switchboard)
        circuits_count = params.dig(:electrical_switchboard, :circuits).presence || params[:circuits].presence
        update_circuits(switchboard, circuits_count.to_i) if circuits_count
      end

      def after_update_hook(switchboard)
        circuits_count = params.dig(:electrical_switchboard, :circuits).presence || params[:circuits].presence
        update_circuits(switchboard, circuits_count.to_i) if circuits_count
      end
  end
end