class CablesController < ApplicationController
  include TagablesController
  
  before_action :authenticate_user!
  before_action :set_cable, only: %i[show edit update destroy]

  # GET /cables or /cables.json
  def index
    @q = policy_scope(Cable).ransack(params[:q])
    @pagy, @cables = pagy(@q.result.includes(:tag), limit: 20)
    authorize @cables
    @orphans = @cables.select{ |cable| cable.tag.nil? }
    @link_errors = current_project.tags.select { |tag| tag.tagable_type == "Cable" && tag.tagable.nil? }
    @link_incomplete = @link_errors.select{ |tag| tag.tagable_id.nil? }
    @link_broken = @link_errors.select{ |tag| !tag.tagable_id.nil? }
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
    @cable = Cable.new(cable_params.except(:tag))
    authorize @cable
    set_tag
    unless @cable.valid?
      # Catch invalid cable params and return to new without further processing 
      setup_form
      flash.now[:alert] = t("flash.actions.create.alert",
                           resource_name: Cable.model_name.human.downcase)
      respond_to do |format|
        format.html { render :new, status: :unprocessable_content }
        format.json { render json: @cable.errors, status: :unprocessable_content }
      end
      return
    end
    if @tag.persisted?
      # Existing tag: Create cable and update tag in one transaction using 
      # delegated_type via the delegator (Tag)
      # This relies on @cable being valid, it won't save invalid tagable, 
      # but won't raise an exception either, hence the check above.
      @tag.update(tagable: @cable)
      flash[:success] = t('flash.tagables.assigned_to',
                        resource_name: Cable.model_name.human,
                        id: @cable.id,
                        tag: @tag.label)
      create_success_redirect
      return
    else
      if @tag.errors.none?
      # New tag from tag params:
      # Create both in one transaction using delegated_type via the delegator (Tag)
        begin
          Cable.transaction do
            @tag.save!
            @tag.update(tagable: @cable)
          end
          flash[:success] = t('flash.tagables.created_and_assigned',
                            resource_name: Cable.model_name.human,
                            id: @cable.id,
                            tag: @tag.label)
          create_success_redirect
          return
        rescue ActiveRecord::RecordInvalid => e
          # Fall through to render :new below
        end
      else
        #tag_id was set but trapped in set_tag
        raise ApplicationController::ConflictError, @tag.errors.first.type
        return
      end
    end
  
    # If we get here, there was a validation error
    setup_form
    flash.now[:alert] = t("flash.actions.create.alert",
                         resource_name: Cable.model_name.human.downcase)
    render :new, status: :unprocessable_content
  end

  # GET /cables/1/edit
  def edit
    authorize @cable

    # Allow edit of cable without a tag as a way to rescue orphans: edit with new tag.
    @tag = @cable.tag&.present? ? @cable.tag : Tag.new(tagable_type: "Cable")
    setup_form
  end

  # PATCH/PUT /cables/1 or /cables/1.json
  def update
    authorize @cable
    @tag = @cable.tag&.present? ? @cable.tag : Tag.new(tag_params.merge(tagable: @cable))
    # Make a dummy cable object for checking cable params
    cable = Cable.new(cable_params.except(:tag))
    unless cable.valid?
      setup_form
      flash.now[:alert] = t("flash.actions.update.alert",
                           resource_name: Cable.model_name.human.downcase)
      render :edit, status: :unprocessable_content
      return
    end
    begin
      if @cable.tag&.persisted?
        # Update existing tag and switchboard
        Cable.transaction do
          @tag = @cable.tag
          @tag.update!(tag_params)
          @cable.update!(cable_params.except(:tag))
        end
      else
        # Create new tag and associate with switchboard
        authorize Tag, :create?
        Cable.transaction do
          @tag = Tag.create!(tag_params.merge(tagable: @cable))
          @cable.update!(cable_params.except(:tag))
        end
      end
      flash[:success] = t("flash.actions.update.notice", resource_name: Cable.model_name.human)
      respond_to do |format|
        format.html { redirect_to @cable }
        format.json { render :show, status: :ok, location: @cable }
      end
    rescue ActiveRecord::RecordInvalid => e
      setup_form
      flash.now[:alert] = t("flash.actions.update.alert", 
                          resource_name: Cable.model_name.human.downcase)
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @cable.errors, status: :unprocessable_entity }
      end
    rescue Pundit::NotAuthorizedError => e
      flash[:danger] = e.message
      redirect_to @cable
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
      @cable.from_type ||= Constants.electrical.connect_options.first
      @cable.to_type ||= Constants.electrical.connect_options.last
      @cable_types = policy_scope(CableType)
      unless @tag&.persisted? # Default tag attributes for switchboard
        @tag.discipline = Discipline.find_by(code: "E")
        @tag.prefix = "EC"
        @tag.tagable_type = "Cable"
      end
      @disciplines = Discipline.all.select(:id, :code, :name).to_a
      # Dynamically build options for all models in constants
      # @id_options is used for the select dropdowns in the cable form for from and to selection
      @id_options = Constants.electrical.connect_options.each_with_object({}) do |model_name, options|
        model_class = model_name.constantize
        
        # Safe policy_scope call with fallback
        begin
          scope = policy_scope(model_class)
          options[model_name] = (scope || []).map { |record| [record.label, record.id] }
        rescue => e
          # Fallback to empty array if policy_scope fails
          Rails.logger.warn "Failed to get policy_scope for #{model_name}: #{e.message}"
          options[model_name] = []
        end
      end
      
      # For Stimulus - translated option names
      @connect_options = Constants.electrical.connect_options.map do |option|
        [t("activerecord.models.#{option.underscore}"), option]
      end 
    end

    def create_success_redirect
      respond_to do |format|
        format.html { redirect_to @cable }
        format.json { render :show, status: :created, location: @cable }
      end
    end

    # Only allow a list of trusted parameters through.
    def cable_params
      params.require(:cable).permit(:cable_type_id, 
        :route_length, :vertical_allowance, :termination_allowance,
        :start_mark, :end_mark, :from_id, :from_type, :to_id, :to_type, 
        tag: [
          :id, :project_id, :discipline_id, :prefix, :serial, 
          :suffix, :service, :stage, :notes, :tagable_type
        ])
    end
end
