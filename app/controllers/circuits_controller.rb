class CircuitsController < ApplicationController
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
      redirect_to @circuit, notice: 'Circuit was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end
  
  def edit
    authorize @circuit
  end
  
  def update
    authorize @circuit
    
    if @circuit.update(circuit_params)
      redirect_to [@switchboard, @circuit], notice: 'Circuit was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end
  
  def destroy
    authorize @circuit
    @circuit.destroy
    redirect_to switchboard_circuits_path(@switchboard), notice: 'Circuit was successfully destroyed.'
  end
  
  private
    def setup_form

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
