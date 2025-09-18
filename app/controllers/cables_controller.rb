class CablesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_tag, only: %i[ new create ]
  before_action :set_cable, only: %i[ show edit update destroy ]

  # GET /cables or /cables.json
  def index
    @q = policy_scope(Cable).ransack(params[:q])
    @pagy, @cables = pagy(@q.result.includes(:tag), limit: 10)
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
    if @tag&.persisted?
      authorize @cable = Cable.new(tag: @tag)
    else
      authorize @cable = Cable.new
    end
  end

  # GET /cables/1/edit
  def edit
    authorize @cable
  end

  # POST /cables or /cables.json
  def create
    @cable = Cable.new(cable_params)
    authorize @cable

    begin
      if @tag.present?
        # Guard: tag already linked
        if @tag.tagable.present?
          return redirect_with(
            :danger,
            t('flash.tags.tagable_already_assigned', tag: @tag.full_tag, resource_name: Cable.model_name.human),
            @tag
          )
        end
        # Guard: tag type is incompatible
        if @tag.tagable_type.present? && @tag.tagable_type != "Cable"
          return redirect_with(
            :danger,
            t('flash.tags.tagable_wrong_type', tag: @tag.full_tag, resource_name: Cable.model_name.human),
            @tag
          )
        end

        ActiveRecord::Base.transaction do
          @tag.update!(tagable: Cable.new(cable_params))
          @cable = @tag.tagable
        end

        # Ensure full_tag is populated for flash text (after_find doesn't run on new instances)
        tag_label = @tag.reload.full_tag
        return redirect_with(
          :success,
          t('flash.tagables.assigned_to', tag: tag_label, resource_name: Cable.model_name.human, id: @cable.id),
          @cable
        )
      else
        # Create both in one shot using delegated_type via the delegator (Tag)
        ActiveRecord::Base.transaction do
          @tag = Tag.create!(tag_params.merge(tagable: Cable.new(cable_params)))
          @cable = @tag.tagable
        end

        # Ensure full_tag is populated for flash text
        tag_label = @tag.reload.full_tag
        return redirect_with(
          :success,
          t('flash.tagables.created_and_assigned', resource_name: Cable.model_name.human, id: @cable.id, tag: tag_label),
          @cable
        )
      end
    rescue ActiveRecord::RecordInvalid => e
      flash.now[:danger] = e.record.errors.full_messages.to_sentence
      return render :new, status: :unprocessable_content
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
      @tag = Tag.find_by(id: params[:tag_id])
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
