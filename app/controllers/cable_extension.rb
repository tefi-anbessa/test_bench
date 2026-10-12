module CableExtension

  private

    def setup_additional_form_data
      # Only set cable attributes if cable exists (prevents errors during validation failures)
      if @cable.present?
        # Default from type to circuit.
        @cable.from_type ||= "Electrical::Circuit"
        # Default to type to demand.
        @cable.to_type ||= "Electrical::Demand"
      end

      cable_type_class = @discipline.cable_type_class
      @cable_types = cable_type_class ? policy_scope(cable_type_class).where(discipline: @discipline) : []
      @cable_type_options = @cable_types.map { |ct| ["#{ct.id}: #{ct.code}", ct.id] }

      # Dynamically build options for all models in constants
      # @id_options is used for the select dropdowns in the cable form for :from and :to selection
      @id_options = Constants.electrical.connect_options.each_with_object({}) do |model_name, options|
        model_class = model_name.constantize

        # Safe policy_scope call with fallback
        begin
          scope = tagable_scope(model_class)
          options[model_name] = (scope || []).map { |record| [record.label, record.id] }
        rescue => e
          # Fallback to empty array if policy_scope fails
          Rails.logger.warn "Failed to get policy_scope for #{model_name}: #{e.message}"
          options[model_name] = []
        end
      end

      # For Stimulus - translated option names
      @connect_options = Constants.electrical.connect_options.map do |option|
        [option.safe_constantize.model_name.human, option]
      end
    end

    # Only allow a list of trusted parameters through. creation_discipline is
    # merged in (not user-submitted) so the model's own discipline/cable_type
    # consistency validation can run on create, before the owning Tag is
    # persisted - see Cable#creation_discipline for why that's needed.
    def tagable_params
      params.require(:cable).permit(:cable_type_id, :cable_type_type,
        :route_length, :vertical_allowance, :termination_allowance,
        :start_mark, :end_mark, :from_id, :from_type, :to_id, :to_type, :notes)
        .merge(creation_discipline: @discipline)
    end
end
