module Electrical
  class CircuitsController < ApplicationController
    before_action :authenticate_user!
    before_action :set_switchboard, only: [:index, :new, :create]
    before_action :set_circuit, only: [:show, :edit, :update, :destroy]
    
    def index
      if @switchboard.present?
        # Cater for index on given switchboard
        authorize @switchboard
        @q = @switchboard.circuits.ransack(params[:q])
        @pagy, @circuits = pagy(@q.result)
      else
        # Cater for index on all circuits in current project
        authorize Electrical::Switchboard
        @q = Electrical::Circuit.joins(switchboard: [tag: [discipline: :project]])
              .merge(policy_scope(Electrical::Switchboard)).ransack(params[:q])
        @pagy, @circuits = pagy(@q.result)
      end
      set_swatch
    end
    
    def show
      authorize @circuit.switchboard
      @neighbours = Navigator.new(scope: @scope, record: @circuit).neighbours
      set_swatch
    end
    
    def new
      authorize @switchboard
      @circuit = @switchboard.circuits.new
      setup_form
    end
    
    def create
      authorize @switchboard
      # Catch enum validation errors
      begin
        attributes = circuit_params
        feeder_id = attributes.delete(:feeder_id)
        demand_id = attributes.delete(:demand_id)
        @circuit = @switchboard.circuits.build
        @circuit.assign_attributes(attributes)
      rescue ArgumentError => _
        # Handle invalid enum values as a conflict
        raise ApplicationController::ConflictError, :invalid_enum
      end
      unless process_cable_params(feeder_id, demand_id)
        setup_form
        render :new, status: :unprocessable_content
        return
      end
      # Ready to complete transactions
      begin 
        @circuit.class.transaction do
          # Create circuit
          @circuit.save!
          # Set feeder cable if specified and valid
          @feeder.update(from: @circuit) if @feeder.present?
          if @demand.present?
            if @demand.incomer&.present?
              # Nullify any existing incomer :to association.
              @demand.incomer.update(to: nil)
            end
            # Set demand as feeder cable :to
            @feeder.update(to: @demand) if @demand.present?
          end
        end
        flash[:success] = [t("flash.create.notice",
                          resource_name: t("activerecord.models.electrical/circuit.one"))]
        flash[:success] << t("flash.assigned", count: 1,
          resource_name: t("activerecord.attributes.electrical/circuit.feeder")) if @feeder.present?
        flash[:success] << t("flash.assigned", count: 1,
          resource_name: t("activerecord.attributes.electrical/circuit.demand")) if @demand.present?
        redirect_to @circuit
      rescue ActiveRecord::RecordInvalid => _e
        # Handle validation errors
        setup_form
        flash.now[:alert] = t("flash.create.alert", 
          resource_name: t("activerecord.models.electrical/circuit.one").downcase)
        render :new, status: :unprocessable_content
      end
    end

    def edit
      authorize @switchboard
      setup_form
    end
    
    def update
      authorize @switchboard
      # Catch enum validation errors
      begin
        attributes = circuit_params
        feeder_id = attributes.delete(:feeder_id)
        demand_id = attributes.delete(:demand_id)
        @circuit.assign_attributes(attributes)
      rescue ArgumentError => _
        # Handle invalid enum values as a conflict
        raise ApplicationController::ConflictError, :invalid_enum
      end
      unless process_cable_params(feeder_id, demand_id)
        setup_form
        render :edit, status: :unprocessable_content
        return
      end

      # Transaction
      begin
        @circuit.class.transaction do
          # Update circuit
          @circuit.save!
          if @feeder.present?
            # Transfer the circuit to feeder
            if @circuit.feeder.present?
              # Nullify any previous cable association
              @circuit.feeder.update(from: nil)
            end
            @feeder.update(from: @circuit)
          end
          # Set demand as feeder cable :to
          if @demand.present?
            if @demand.incomer&.present?
              # Nullify any previous incomer :to association.
              @demand.incomer.update(to: nil)
            end
            if @feeder.present?
              # Set demand on replacement feeder cable
              @feeder.update(to: @demand)
            else
              if @circuit.feeder&.present?
                # Set demand on existing feeder cable
                @circuit.feeder.update(to: @demand)
              else
                # Should have been trapped in process_cable_params. 
                # Cannot set a demand when no feeder existing or requested.
              end
            end
          end
        end
        flash[:success] = [t("flash.update.notice",
                          resource_name: t("activerecord.models.electrical/circuit.one"))]
        flash[:success] << t("flash.assigned", count: 1,
          resource_name: t("activerecord.attributes.electrical/circuit.feeder")) if @feeder.present?
        flash[:success] << t("flash.assigned", count: 1,
          resource_name: t("activerecord.attributes.electrical/circuit.demand")) if @demand.present?
        redirect_to @circuit
      rescue ActiveRecord::RecordInvalid
        # Handle validation errors
        flash.now[:alert] = t("flash.update.alert",
          resource_name: t("activerecord.models.electrical/circuit.one").downcase)
        setup_form
        render :edit, status: :unprocessable_content
      end
    end
    
    def destroy
      authorize @switchboard
      if @circuit.destroy
        flash[:success] = t("flash.destroy.notice", resource_name: t("activerecord.models.electrical/circuit.one"))
      else
        flash.now[:alert] = t("flash.destroy.alert", resource_name: t("activerecord.models.electrical/circuit.one").downcase)
      end
      redirect_to electrical_switchboard_circuits_path(@switchboard)
    end
    
    private
      
      def set_switchboard
        if params[:switchboard_id].present?
          # Index for single switchboard
          @switchboard = policy_scope(Electrical::Switchboard).find_by(id: params[:switchboard_id])
          raise ApplicationController::ConflictError, :out_of_scope if @switchboard.nil?
          @discipline = @switchboard.discipline
        else
          # Index for complete discipline
          @switchboard = nil
          @discipline = policy_scope(Discipline).find_by(id: params[:discipline_id])
          raise ApplicationController::ConflictError, :out_of_scope if @discipline.nil?
        end
      end
      
      def set_circuit
        @circuit = Electrical::Circuit.joins(:switchboard)
              .merge(policy_scope(Electrical::Switchboard))
              .find_by(id: params[:id])
        raise ApplicationController::ConflictError, :out_of_scope if @circuit.nil?
        @switchboard = @circuit.switchboard
        @scope = @switchboard.circuits
          .joins(switchboard: { tag: { discipline: :project } })
      end

      def set_swatch
        @swatch = @switchboard&.discipline&.swatch || Electrical::Circuit.swatch
      end

      def process_cable_params(feeder_id, demand_id) 
        @feeder = @demand = nil
        # Only assign feeder if the param is not pointing to the present @circuit
        feeder_id = feeder_id.present? ? feeder_id.to_i : nil

        if feeder_id.present? && (feeder_id != @circuit.feeder&.id)
          # Only assign feeder if the param is not pointing to the present @circuit.
          # This code at present cannot reset the feeder to nil.
          @feeder = set_feeder(feeder_id)
          # set_feeder checks request is in scope and raises conflict error if not...
          return false if @feeder.nil?
        end
        demand_id = demand_id.present? ? demand_id.to_i : nil
        if demand_id.present? && demand_id != @circuit.feeder&.to_id
          # Only assign demand if the param is set and it is not pointing to the present @circuit.
          # This code at present cannot reset the demand to nil.
          @demand = set_demand(demand_id)
          # set_demand checks that demand is in scope and raises conflict error if not...
          return false if @demand.nil?
        end
        # No errors or no cable params changed
        true
      end

      # User can allocate a feeder cable from the circuit form, only if the cable is presently unallocated.
      # To change an existing allocation, user must edit the cable itself.
      def set_feeder(feeder_id)
        # Check that the cable requested exists and is in scope
        unless feeder = policy_scope(Electrical::Cable).find_by(id: feeder_id)
          raise ApplicationController::ConflictError, :invalid_assignment
        end

        # Check that user has permission to edit cable
        unless policy(feeder).edit?
          flash[:alert] = t("pundit.unauthorized", 
                                action: t("actions.edit"), 
                                objects: @circuit.feeder.model_name.human.pluralize.downcase)
          return nil
        end
        
        # Checks complete: Return the feeder cable object.
        return feeder
      end

      def set_demand(demand_id)
        # Ensure the circuit's feeder is assigned, or is being set in this operation.
        # Required to set demand (as feeder.to)
        feeder = @feeder || @circuit.feeder
        unless feeder&.persisted?
          flash[:alert] = t("flash.required", resource_name: t("activerecord.attributes.electrical/circuit.feeder"))
          return nil
        end

        # Check that the demand requested exists and is in scope
        unless demand = policy_scope(Electrical::Demand).find_by(id: demand_id)
          raise ApplicationController::ConflictError, :invalid_assignment
        end

        # Check that user has permission to edit the feeder
        unless policy(feeder).edit?
          flash[:alert] = t("pundit.unauthorized", 
                                action: t("actions.edit"), 
                                objects: feeder.model_name.human.pluralize.downcase)
          return nil
        end

        # Return the demand object
        return demand
      end

      def setup_form
        # Filter cables that are not already assigned as feeders (from association is nil)
        # but include the current assignment to show selected on form.
        @cables = policy_scope(Electrical::Cable).where(from: nil)
                                .or(policy_scope(Electrical::Cable).where(from: @circuit))
                                .map { |cable| [cable.label, cable.id] }
        @cable = policy_scope(Electrical::Cable).first # dummy cable for policy testing
        
        # Filter demands that don't already have an incomer cable
        # Build the base scope for demands
        demands_scope = policy_scope(Electrical::Demand)
        
        # Find demands without an incomer
        demands_without_incomer = demands_scope
          .where.not(id: Electrical::Cable.where(to_type: 'Electrical::Demand').where.not(to_id: nil).select(:to_id))
        
        # If there's a current feeder, include its target demand
        if @circuit.feeder&.to_id.present?
          demands = demands_without_incomer.or(demands_scope.where(id: @circuit.feeder.to_id))
        else
          demands = demands_without_incomer
        end

        @demands = demands.map { |demand| [demand.label, demand.id] }
        @demand = Electrical::Demand.new() # dummy instance for bootstrap fields
        set_swatch
      end
      
      def circuit_params
        params.require(:electrical_circuit).permit(
          :serial, :phase, :device, :poles, :curve, :rating, :elcb, :contactor, :notes, :feeder_id, :demand_id
        )
      end
  end
end