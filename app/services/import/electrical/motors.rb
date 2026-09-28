# app/services/import/electrical/motors.rb
module Import
  module Electrical
    # Electrical::Motor plugin for the import framework - see
    # Import::TagableBase for what's generic to every tagable importer (it
    # always attaches to an already-persisted, unassigned Tag by natural key -
    # never creates a Tag). Resolved by
    # Import::Base.registered("electrical/motors") via naming convention. The
    # hand-built reference implementation the project_assistant:import
    # generator's --tagable mode is verified against.
    class Motors < TagableBase
      def model_class
        ::Electrical::Motor
      end

      def permitted_attributes
        ::Electrical::Motor::IMPORTABLE_ATTRIBUTES
      end

      def own_column_definitions
        [
          # motor_type/frame_size are both enums (see Electrical::Motor) -
          # normalizing case/spacing here means "Induction" or "induction "
          # from a real spreadsheet still matches the enum key, rather than
          # failing record validation with a raw ArgumentError.
          ColumnDefinition.new(key: :motor_type, label: "Motor Type", required: true,
            coercer: ->(value) { value.to_s.strip.downcase.tr(" ", "_").presence }),
          ColumnDefinition.new(key: :frame_size, label: "Frame Size",
            coercer: ->(value) { value.to_s.strip.presence }),
          ColumnDefinition.new(key: :poles, label: "Poles", coercer: ->(value) { value.to_s.strip.presence&.to_i }),
          ColumnDefinition.new(key: :ingress_protection, label: "Ingress Protection", aliases: ["IP Rating", "IP"]),
          ColumnDefinition.new(key: :speed_rated, label: "Speed Rated", aliases: ["Rated Speed"],
            coercer: ->(value) { value.to_s.strip.presence&.to_f }),
          ColumnDefinition.new(key: :notes, label: "Notes")
        ]
      end
    end
  end
end
