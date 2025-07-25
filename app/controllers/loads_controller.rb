class LoadsController < ApplicationController
  before_action :set_tag, only: %i[ new, create ]
  before_action :set_load, only: %i[ show edit update destroy ]

  # GET /loads
  def index
    @orphans = Load.includes(:tag).select{ |o| o.tag.nil? }
    @link_errors = Tag.loads.includes(:tagable).select{ |tag| tag.load.nil? }
    @link_incomplete = @link_errors.select{ |tag| tag.tagable_id.nil? }
    @link_broken = @link_errors.select{ |tag| !tag.tagable_id.nil? }
    @q = Load.ransack(params[:q])
    @pagy, @loads = pagy(@q.result, limit: 10)
  end

  # GET /loads/1 or /loads/1.json
  def show
  end

  # GET /tag/1/loads/new
  def new
    @load = @tag.build_tagable()
    case @tag.prefix
    when "EX"
      @load.basis = "summation"
    when /[A,K,P]M/
      @load.basis = "power_pf"
    end
  end

  # GET /loads/1/edit
  def edit
  end

  def create
    if @load = Load.create!((load_params).except(:tag_id))
      @tag.update(tagable_id: @load.id)
      flash[:success] = "Load created"
      redirect_to @load
    else
      render 'new', status: :unprocessable_entity
    end
  end

  # PATCH/PUT /loads/1 or /loads/1.json
  def update
    respond_to do |format|
      if @load.update((load_params).except(:tag_id))
        format.html { redirect_to @load, notice: "Load was successfully updated." }
        format.json { render :show, status: :ok, location: @load }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @load.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /loads/1 or /loads/1.json
  def destroy
    unless @load.tag.nil?
      @load.tag.tagable_id = nil
    end
    @load.destroy

    respond_to do |format|
      format.html { redirect_to loads_path, status: :see_other, notice: "Load was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private

    def set_load
      @load = Load.find(params[:id])
      @tag = @load.tag
    end

    def set_tag
      params.permit(:tag_id)
      @tag = Tag.find(params.permit(:locale, :tag_id)[:tag_id])
    end

    def load_params
      params.require(:load).permit(:tag_id, :id, :circuit, :basis, :basis_notes,
                                    :supply, :other_supply, :config, :power,
                                    :vector, :power_factor, :current, :duty,
                                    :loadable_type, :loadable_id)
    end

    def new_params
    end
end
