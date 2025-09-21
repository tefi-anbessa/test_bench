class CablesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_cable, only: %i[ show edit update destroy ]
  before_action :setup_form, only: %i[ new edit ]

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

  # GET /cables/1/edit
  def edit
    authorize @cable
  end

  # POST /cables or /cables.json
  def create
    @cable = Cable.new(cable_params)
    authorize @cable
    return unless set_tag

    # Set project context if creating a new tag
    if params[:tag].present? && params[:tag][:project_id].blank? && current_project.present?
      params[:tag][:project_id] = current_project.id
    end

    if @tag&.persisted?
      # Create cable and update tag in one transaction using delegated_type via the delegator (Tag)
      if @tag.update!(tagable: @cable)
        @tag.reload
        return redirect_with(:success,
          t('flash.tagables.assigned_to', tag: @tag.label, 
            resource_name: Cable.model_name.human,
            id: @cable.id), @cable)
      else
        setup_form
        render :new, status: :unprocessable_content
      end
    else
      # Create both in one transaction using delegated_type via the delegator (Tag)
      @tag = Tag.new(tag_params.merge(tagable: @cable))
      if @tag.save
      # Ensure full_tag is populated for flash text
        @tag.reload
        return redirect_with(
          :success,
          t('flash.tagables.created_and_assigned', 
            resource_name: Cable.model_name.human, 
            id: @cable.id, 
            tag: @tag.label),
          @cable
        )
      else
        setup_form
        render :new, status: :unprocessable_content
      end
    end
  end

  # PATCH/PUT /cables/1 or /cables/1.json
  def update
    authorize @cable
    respond_to do |format|
      if @cable.update(cable_params)
        format.html {
          redirect_to @cable,
            notice: t('flash.actions.update.notice', resource_name: Cable.model_name.human)
        }
        format.json { render :show, status: :ok, location: @cable }
      else
        format.html {
          flash.now[:alert] = t('flash.actions.update.alert', resource_name: Cable.model_name.human)
          render :edit, status: :unprocessable_content
        }
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

    def set_tag
      # Handle case when creating a new tag
      if params[:tag].present?
        @tag = Tag.new(tag_params)
        
        # Validate the tag
        unless @tag.valid?
          @cable = Cable.new(cable_params) if params[:cable].present? # Initialize cable with any params
          @tag = Tag.new(tag_params) # Re-initialize with submitted tag params to maintain form state
          setup_form
          render :new, status: :unprocessable_content and return false
        end
        
      # Handle case when linking to existing tag through tagable_id association
      elsif params[:tag_id].present?
        @tag = Tag.find_by(id: params[:tag_id])
        if @tag.nil?
          redirect_to cables_path, danger: 'Tag not found.' and return false
          # Trap: attempt to link to non-existent tag, not possible within work flows available.
        end
        
        # Guard: tag already linked
        if @tag.tagable.present?
          redirect_with(
            :danger,
            t('flash.tags.tagable_already_assigned', 
              tag: @tag.full_tag, 
              resource_name: Cable.model_name.human),
            @tag
          ) and return false
        end
      
        # Guard: tag type is incompatible
        if @tag.tagable_type.present? && @tag.tagable_type != "Cable"
          redirect_with(
              :danger,
              t('flash.tags.tagable_wrong_type', 
                tag: @tag.full_tag, 
                resource_name: Cable.model_name.human),
              @tag
            ) and return
        end
        # @tag is set to valid tag for cable creation

      # Handle case when using the new form to create a new tag
      else
        @tag = Tag.new()
      end
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

    def tag_params
      params.require(:tag).permit(:project_id, :discipline_id, :prefix, :serial, :suffix, :service, :stage, :notes)
    end

    def redirect_with(level, message, location)
      flash[level] = message
      redirect_to location
    end
end
