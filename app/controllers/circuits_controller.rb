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
  end
  
  def new
    @circuit = @switchboard.circuits.new
    authorize @circuit
  end
  
  def create
    @circuit = @switchboard.circuits.new(circuit_params)
    authorize @circuit
    
    if @circuit.save
      flash[:success] = t("flash.actions.create.notice", resource_name: Circuit.model_name.human)
      redirect_to @circuit
    else
      flash.now[:alert] = t("flash.actions.create.alert", resource_name: Circuit.model_name.human)
      render :new, status: :unprocessable_entity
    end
  end
  
  def edit
    authorize @circuit
  end
  
  def update
    authorize @circuit
    
    if @circuit.update(circuit_params)
      flash[:success] = t("flash.actions.update.notice", resource_name: Circuit.model_name.human)
      redirect_to [@switchboard, @circuit]
    else
      flash.now[:alert] = t("flash.actions.update.alert", resource_name: Circuit.model_name.human)
      render :edit, status: :unprocessable_entity
    end
  end
  
  def destroy
    authorize @circuit
    switchboard = @circuit.switchboard
    @circuit.destroy
    flash[:success] = t("flash.actions.destroy.notice", resource_name: Circuit.model_name.human)
    redirect_to switchboard_circuits_path(switchboard)
  end
  
  private
    def setup_form
      @cables = policy_scope(Cable).map { |cable| [cable.label, cable.id] }
      @demands = policy_scope(Demand).map { |demand| [demand.label, demand.id] }
    end
    
    def set_switchboard
      @switchboard = Switchboard.find(params[:switchboard_id]) if params[:switchboard_id].present?
    end
    
    def set_circuit
      @circuit = Circuit.find(params[:id])
    end
    
    def circuit_params
      params.require(:circuit).permit(
        :serial, :phase, :device, :poles, :curve, :rating, :elcb, :contactor, :notes
      )
    end
end
