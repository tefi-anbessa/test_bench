class CablesController < ApplicationController
  include TagablesController
  
  before_action :authenticate_user!
  before_action :set_cable, only: %i[show edit update destroy]

  # GET /cables or /cables.json
  def index
    @q = policy_scope(Cable).ransack(params[:q])
    @pagy, @cables = pagy(@q.result.includes(:tag), limit: 20)
    @orphans = @cables.select{ |cable| cable.tag.nil? }
    @link_errors = current_project.tags.where(tagable_type: "Cable", tagable_id: nil)
    @link_incomplete = @link_errors.select{ |tag| tag.tagable_id.nil? }
    @link_broken = @link_errors.select{ |tag| !tag.tagable_id.nil? }
    authorize @cables
  end

  # GET /cables/1 or /cables/1.json
  def show
    authorize @cable
  end

  # GET /cables/new
  def new
    authorize @cable = Cable.new()
    set_tag
    setup_form
  end

  # POST /cables or /cables.json
  def create
    @cable = Cable.new(cable_params)
    authorize @cable
    set_tag
  
    # Set project context if creating a new tag
    if params[:tag].present? && params[:tag][:project_id].blank? && current_project.present?
      params[:tag][:project_id] = current_project.id
    end
  
    
    if @tag.nil?
      # @tag is set to nil in set_tag when a security breach attempt is detected.
      Rails.logger.warn(
        "Forbidden: Invalid tag association - " \
        "Tag: #{@tag&.inspect}, " \
        "Expected type: #{controller_name.classify}, " \
        "User: #{current_user&.id}"
      )
      trap_forbidden
      return
    else
      if @tag.persisted?
        # Existing tag: Create cable and update tag in one transaction using 
        # delegated_type via the delegator (Tag)
        if @cable.valid? && @tag.update(tagable: @cable)
          @tag.reload
          flash[:success] = t('flash.tagables.assigned_to',
                            resource_name: Cable.model_name.human,
                            id: @cable.id,
                            tag: @tag.label)
          redirect_to @cable
          return
        else
          # Fall through to render :new below
        end
      else
        unless @tag_invalid
          # New tag from tag params:
          # Create both in one transaction using delegated_type via the delegator (Tag)
          begin
            Cable.transaction do
              @cable.save!
              @tag.tagable = @cable
              @tag.save!
            end
            flash[:success] = t('flash.tagables.created_and_assigned',
                              resource_name: Cable.model_name.human,
                              id: @cable.id,
                              tag: @tag.label)
            redirect_to @cable
            return
          rescue ActiveRecord::RecordInvalid => e
            # Fall through to render :new below
          end
        end
      end
    end
  
    # If we get here, there was a validation error
    setup_form
    flash.now[:danger] = t("flash.actions.create.alert",
                         resource_name: Cable.model_name.human.downcase)
    render :new, status: :unprocessable_content
  end

  # GET /cables/1/edit
  def edit
    authorize @cable
    setup_form
  end

  # PATCH/PUT /cables/1 or /cables/1.json
  def update
    authorize @cable
    
    respond_to do |format|
      if @cable.update(cable_params)
        format.html do
          flash[:success] = t("flash.actions.update.notice", resource_name: Cable.model_name.human)
          redirect_to @cable
        end
        format.json { render :show, status: :ok, location: @cable }
      else
        setup_form
        flash.now[:alert] = t("flash.actions.update.alert", resource_name: Cable.model_name.human.downcase)
        format.html { render :edit, status: :unprocessable_content }
        format.json { render json: @cable.errors, status: :unprocessable_content }
      end
    end
  end

  # DELETE /cables/1 or /cables/1.json
  def destroy
    authorize @cable
    @cable.destroy

    respond_to do |format|
      format.html {
        redirect_to cables_path,
          status: :see_other,
          notice: t('flash.actions.destroy.notice', resource_name: Cable.model_name.human)
      }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_cable
      @cable = Cable.find(params[:id])
    end

    def setup_form
      @cable_types = policy_scope(CableType)
      @circuits = policy_scope(Circuit)
    end

    # Only allow a list of trusted parameters through.
    def cable_params
      params.require(:cable).permit(:cable_type_id, :circuit_id, :load_id, 
        :route_length, :vertical_allowance, :termination_allowance,
        :start_mark, :end_mark)
    end

    def redirect_with(level, message, location)
      flash[level] = message
      redirect_to location
    end
end
