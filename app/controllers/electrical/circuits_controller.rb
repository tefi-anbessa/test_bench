module Electrical
  class CircuitsController < ApplicationController
    before_action :authenticate_user!
    before_action :set_switchboard, only: [:index, :new, :create]
    before_action :set_circuit, only: [:show, :edit, :update, :destroy]
    before_action :set_swatch, only: [:index, :show, :new, :edit]
    
    def index
      authorize Electrical::Circuit
      if @switchboard.present?
        @q = policy_scope(@switchboard.electrical_circuits).ransack(params[:q])
      else
        @q = policy_scope(Electrical::Circuit).ransack(params[:q])
      end
      @pagy, @circuits = pagy(@q.result)
    end
    
    def show
      authorize @circuit
    end
    
    def new
      @circuit = @switchboard.electrical_circuits.new
      authorize @circuit
      setup_form
    end
    
    def create
      @circuit = @switchboard.electrical_circuits.new(circuit_params.except(:cable))
      authorize @circuit
      
      if @circuit.save
        flash[:success] = [t("flash.create.notice", resource_name: @circuit.model_name.human)]
        
        # Only assign feeder if it's different from current (prevents "already assigned" error)
        feeder_id = params.dig(:cable, :from_id).presence
        if feeder_id && feeder_id != @circuit.feeder&.id
          if set_feeder
            flash[:success] << t("flash.assigned", resource_name: Electrical::Circuit.human_attribute_name(:feeder))
          end
        end
        
        # Only assign demand if it's different from current (prevents "already assigned" error)
        demand_id = params.dig(:cable, :to_id).presence
        if demand_id && demand_id != @circuit.reload.feeder&.to&.id
          if set_demand
            flash[:success] << t("flash.assigned", resource_name: Electrical::Circuit.human_attribute_name(:demand))
          end
        end
        # Create complete
        redirect_to @circuit
      else
        flash.now[:alert] = t("flash.create.alert", resource_name: @circuit.model_name.human)
        setup_form
        render :new, status: :unprocessable_entity
      end
    end
    
    def edit
      authorize @circuit
      setup_form
    end
    
    def update
      authorize @circuit
      if @circuit.update(circuit_params)
        flash[:success] = [t("flash.actions.update.notice", resource_name: @circuit.model_name.human)]
        
        # Only assign feeder if it's different from current (prevents "already assigned" error)
        feeder_id = params.dig(:cable, :from_id).presence
        if feeder_id && feeder_id != @circuit.feeder&.id
          if set_feeder 
            flash[:success] << t("flash.assigned", resource_name: Electrical::Circuit.human_attribute_name(:feeder))
          end
        end
        
        # Only assign demand if it's different from current (prevents "already assigned" error)
        demand_id = params.dig(:cable, :to_id).presence
        if demand_id && demand_id != @circuit.reload.feeder&.to&.id
          if set_demand
            flash[:success] << t("flash.assigned", resource_name: Electrical::Circuit.human_attribute_name(:demand))
          end
        end
        # Updates complete
        redirect_to @circuit
      else
        # Update failed, probably validation error
        flash.now[:alert] = t("flash.update.alert", resource_name: @circuit.model_name.human)
        setup_form
        render :edit, status: :unprocessable_entity
      end
    end
    
    def destroy
      authorize @circuit
      switchboard = @circuit.electrical_switchboard
      if @circuit.destroy
        flash[:success] = t("flash.destroy.notice", resource_name: @circuit.model_name.human)
      else
        flash.now[:alert] = t("flash.destroy.alert", resource_name: @circuit.model_name.human)
      end
      redirect_to electrical_switchboard_circuits_path(switchboard)
    end
    
    private
      def setup_form
        # Filter cables that are not already assigned as feeders (from association is nil)
        # but include the current assignment to show selected on form.
        @cables = policy_scope(Electrical::Cable).where(from: nil)
                                .or(policy_scope(Electrical::Cable).where(from: @circuit))
                                .map { |cable| [cable.label, cable.id] }
        @cable = Electrical::Cable.new() # dummy instance for bootstrap fields
        
        # Filter demands that don't already have an incomer cable
        # Build the base scope for demands
        demands_scope = policy_scope(Electrical::Demand)
        
        # Find demands without an incomer
        demands_without_incomer = demands_scope
          .where.not(id: Electrical::Cable.where(to_type: 'Electrical::Demand').select(:to_id))
        
        # If there's a current feeder, include its target demand
        if @circuit.feeder&.to_id.present?
          demands = demands_without_incomer.or(demands_scope.where(id: @circuit.feeder.to_id))
        else
          demands = demands_without_incomer
        end

        @demands = demands.map { |demand| [demand.label, demand.id] }
        @demand = Electrical::Demand.new() # dummy instance for bootstrap fields
      end
      
      def set_switchboard
        @switchboard = Electrical::Switchboard.find(params[:switchboard_id])
      end
      
      def set_circuit
        @circuit = Electrical::Circuit.find(params[:id])
        @switchboard = @circuit.electrical_switchboard
      end

      def set_swatch
        @swatch = Electrical::Circuit.swatch
      end

      # User can allocate a feeder cable from the circuit form, only if the cable is presently unallocated.
      # To change an existing allocation, user must edit the cable itself.
      def set_feeder
        # Check that the cable requested exists and is in scope
        unless @feeder = policy_scope(Electrical::Cable).find_by(id: params.dig(:cable, :from_id))
          flash[:alert] = t("flash.not_found", resource_name: Electrical::Circuit.human_attribute_name(:feeder))
          return false
        end

        # Check that user has permission to edit cable
        unless policy(@feeder).edit?
          flash[:alert] = t("pundit.unauthorized", 
                                action: t("actions.edit"), 
                                objects: @circuit.feeder.model_name.human.pluralize.downcase)
          return false
        end
          
        # Check whether cable is already assigned to a from object.
        if @feeder&.from&.persisted?
            flash[:alert] = t("flash.already_assigned", resource_name: Electrical::Circuit.human_attribute_name(:feeder))
          return false
        end
        
        # Make the update to the feeder cable
        unless @feeder.update(from: @circuit)
          flash[:alert] = t("flash.update.alert", resource_name: Electrical::Circuit.human_attribute_name(:demand))
          return false
        end
        
        # Return the feeder cable object - not used but suffices as true.
        return @feeder
      end

      def set_demand
        # Ensure feeder is assigned, required to set demand (as feeder.to)
        unless @circuit&.feeder&.persisted?
          flash[:alert] = t("flash.required", resource_name: Electrical::Circuit.human_attribute_name(:feeder))
          return false
        end

        # Check that a valid demand id has been requested
        unless demand = policy_scope(Electrical::Demand).find_by(id: params[:cable][:to_id])
          flash[:alert] = t("flash.not_found", resource_name: Electrical::Circuit.human_attribute_name(:demand))
          return false
        end

        # If feeder already has a valid :to object, or demand already has a valid :incomer, do nothing
        if @circuit.feeder.to&.persisted? || demand.incomer&.persisted?
          flash[:alert] = t("flash.already_assigned", resource_name: Electrical::Circuit.human_attribute_name(:demand))
          return false
        end

        # Check that user has permission to edit the feeder
        unless policy(@circuit.feeder).edit?
          flash[:alert] = t("pundit.unauthorized", 
                                action: t("actions.edit"), 
                                objects: @circuit.feeder.model_name.human.pluralize.downcase)
          return false
        end
        # Edit the feeder cable :to field
        unless @circuit.feeder.update(to: demand)
          flash[:alert] = t("flash.update.alert", resource_name: Electrical::Circuit.human_attribute_name(:demand))
          return false
        end

        # Return the demand object - not used but suffices as true.
        return demand
      end
      
      def circuit_params
        params.require(:electrical_circuit).permit(
          :serial, :phase, :device, :poles, :curve, :rating, :elcb, :contactor, :notes, :submit
        )
      end
  end
end