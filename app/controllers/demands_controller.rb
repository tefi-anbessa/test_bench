class DemandsController < ApplicationController
  before_action :set_tag, only: %i[ new, create ]
  before_action :set_demand, only: %i[ show edit update destroy ]

  # GET /demands
  def index
    @orphans = Demand.includes(:tag).select{ |o| o.tag.nil? }
    @link_errors = Tag.loads.includes(:tagable).select{ |tag| tag.tagable.nil? }
    @link_incomplete = @link_errors.select{ |tag| tag.tagable_id.nil? }
    @link_broken = @link_errors.select{ |tag| !tag.tagable_id.nil? }
    @q = Demand.ransack(params[:q])
    @pagy, @demands = pagy(@q.result, limit: 10)
  end

  # GET /demands/1 or /demands/1.json
  def show
  end

  # GET /tag/1/demands/new
  def new
    @demand = @tag.build_tagable()
    case @tag.prefix
    when "EX"
      @demand.basis = "summation"
    when /[A,K,P]M/
      @demand.basis = "power_pf"
    end
  end

  # GET /demands/1/edit
  def edit
  end

  def create
    @demand = Demand.create!(demand_params.except(:tag_id))
    @tag.update(tagable: @demand)
    flash[:success] = "Demand created"
    redirect_to @demand
  rescue ActiveRecord::RecordInvalid => e
    @demand = e.record
    render 'new', status: :unprocessable_entity
  end

  # PATCH/PUT /demands/1 or /demands/1.json
  def update
    respond_to do |format|
      if @demand.update(demand_params.except(:tag_id))
        format.html { redirect_to @demand, notice: "Demand was successfully updated." }
        format.json { render :show, status: :ok, location: @demand }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @demand.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /demands/1 or /demands/1.json
  def destroy
    @demand.destroy
    respond_to do |format|
      format.html { redirect_to demands_url, status: :see_other, notice: "Demand was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_demand
      @demand = Demand.find(params[:id])
      @tag = @demand.tag
    end

    def set_tag
      @tag = Tag.find(params[:tag_id])
    end

    # Only allow a list of trusted parameters through.
    def demand_params
      params.require(:demand).permit(:basis, :config, :supply, :power, :current, :power_factor, :duty, :tag_id, :other_supply, :loadable_type, :loadable_id)
    end
end
