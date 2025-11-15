class CircuitsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_switchboard, only: [:index, :new, :create]
  before_action :set_circuit, only: [:show, :edit, :update, :destroy]
  
  def index
    if @switchboard.present?
      @circuits = policy_scope(@switchboard.circuits).order(:serial)
    else
      @circuits = policy_scope(Circuit).order(:serial)
    end
    authorize @circuits
  end
  
  def show
    authorize @circuit
    setup_form
  end
  
  def new
    @circuit = @switchboard.circuits.new
    authorize @circuit
    setup_form
  end
  
  def create
    @circuit = @switchboard.circuits.new(circuit_params.except(:feeder_id, :demand_id))
    authorize @circuit
    
    if @circuit.save
      flash[:success] = [t("flash.create.notice", resource_name: Circuit.model_name.human)]
      
      # Only assign feeder if it's different from current (prevents "already assigned" error)
      feeder_id = params.dig(:cable, :from_id).presence
      if feeder_id && feeder_id != @circuit.feeder&.id
        if set_feeder
          flash[:success] << t("flash.assigned", resource_name: Circuit.human_attribute_name(:feeder))
        end
      end
      
      # Only assign demand if it's different from current (prevents "already assigned" error)
      demand_id = params.dig(:cable, :to_id).presence
      if demand_id && demand_id != @circuit.reload.feeder&.to&.id
        if set_demand
          flash[:success] << t("flash.assigned", resource_name: Circuit.human_attribute_name(:demand))
        end
      end
      # Create complete
      redirect_to @circuit
    else
      flash.now[:alert] = t("flash.actions.create.alert", resource_name: Circuit.model_name.human)
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
      flash[:success] = [t("flash.actions.update.notice", resource_name: Circuit.model_name.human)]
      
      # Only assign feeder if it's different from current (prevents "already assigned" error)
      feeder_id = params.dig(:cable, :from_id).presence
      if feeder_id && feeder_id != @circuit.feeder&.id
        if set_feeder 
          flash[:success] << t("flash.assigned", resource_name: Circuit.human_attribute_name(:feeder))
        end
      end
      
      # Only assign demand if it's different from current (prevents "already assigned" error)
      demand_id = params.dig(:cable, :to_id).presence
      if demand_id && demand_id != @circuit.reload.feeder&.to&.id
        if set_demand
          flash[:success] << t("flash.assigned", resource_name: Circuit.human_attribute_name(:demand))
        end
      end
      # Updates complete
      redirect_to @circuit
    else
      # Update failed, probably validation error
      flash.now[:alert] = t("flash.update.alert", resource_name: Circuit.model_name.human)
      setup_form
      render :edit, status: :unprocessable_entity
    end
  end
  
  def destroy
    authorize @circuit
    switchboard = @circuit.switchboard
    @circuit.destroy
    flash[:success] = t("flash.destroy.notice", resource_name: Circuit.model_name.human)
    redirect_to switchboard_circuits_path(switchboard)
  end
  
  private
    def setup_form
      # Filter cables that are not already assigned as feeders (from association is nil)
       # but include the current assignment to show selected on form.
      @cables = policy_scope(Cable).where(from: nil)
                               .or(policy_scope(Cable).where(from: @circuit))
                               .map { |cable| [cable.label, cable.id] }
      @cable = Cable.new() # dummy instance for bootstrap fields

      # Filter demands that don't have an incomer cable (LEFT JOIN to find demands without cables)
      @demands = policy_scope(Demand).left_joins(:incomer)
                                .where(cables: { id: nil })
                                .or(policy_scope(Demand).where(id: @circuit.feeder&.to&.id))
                                .map { |demand| [demand.label, demand.id] }
      @demand = Demand.new() # dummy instance for bootstrap fields
    end
    
    def set_switchboard
      @switchboard = Switchboard.find(params[:switchboard_id]) if params[:switchboard_id].present?
    end
    
    def set_circuit
      @circuit = Circuit.find(params[:id])
    end

    # User can allocate a feeder cable from the circuit form, only if the cable is presently unallocated.
    # To change an existing allocation, user must edit the cable itself.
    def set_feeder
      # Check that the cable requested exists and is in scope
      unless @feeder = policy_scope(Cable).find_by(id: params.dig(:cable, :from_id))
        flash[:alert] = t("flash.not_found", resource_name: Circuit.human_attribute_name(:feeder))
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
          flash[:alert] = t("flash.already_assigned", resource_name: Circuit.human_attribute_name(:feeder))
        return false
      end
      
      # Make the update to the feeder cable
      unless @feeder.update(from: @circuit)
        flash[:alert] = t("flash.update.alert", resource_name: Circuit.human_attribute_name(:demand))
        return false
      end
      
      # Return the feeder cable object - not used but suffices as true.
      return @feeder
    end

    def set_demand
      # Ensure feeder is assigned, required to set demand (as feeder.to)
      unless @circuit&.feeder&.persisted?
        flash[:alert] = t("flash.required", resource_name: Circuit.human_attribute_name(:feeder))
        return false
      end

      # Check that a valid demand id has been requested
      unless demand = policy_scope(Demand).find_by(id: params[:cable][:to_id])
        flash[:alert] = t("flash.not_found", resource_name: Circuit.human_attribute_name(:demand))
        return false
      end

      # If feeder already has a valid :to object, or demand already has a valid :incomer, do nothing
      if @circuit.feeder.to&.persisted? || demand.incomer&.persisted?
        flash[:alert] = t("flash.already_assigned", resource_name: Circuit.human_attribute_name(:demand))
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
        flash[:alert] = t("flash.update.alert", resource_name: Circuit.human_attribute_name(:demand))
        return false
      end

      # Return the demand object - not used but suffices as true.
      return demand
    end
    
    def circuit_params
      params.require(:circuit).permit(
        :serial, :phase, :device, :poles, :curve, :rating, :elcb, :contactor, :notes
      )
    end
end
