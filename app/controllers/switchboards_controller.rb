class SwitchboardsController < ApplicationController
  include TagablesController
  
  before_action :authenticate_user!
  before_action :set_switchboard, only: %i[show edit update destroy]

  # GET /switchboards or /switchboards.json
  def index
    @q = policy_scope(Switchboard).ransack(params[:q])
    @pagy, @switchboards = pagy(@q.result.includes(:tag), limit: 20)
    @orphans = @switchboards.select{ |switchboard| switchboard.tag.nil? }
    @link_errors = current_project.tags.where(tagable_type: "Switchboard", tagable_id: nil)
    @link_incomplete = @link_errors.select{ |tag| tag.tagable_id.nil? }
    @link_broken = @link_errors.select{ |tag| !tag.tagable_id.nil? }
    authorize @switchboards
  end

  # GET /switchboards/1 or /switchboards/1.json
  def show
    authorize @switchboard
  end

  # GET /switchboards/new
  def new
    authorize @switchboard = Switchboard.new()
    set_tag
    if @tag.nil?
      # @tag is set to nil in set_tag when a security breach attempt is detected.
      tag_nil
      return nil
    end
    if @tag.persisted?
      # Occurs when params[tag_id] is present
      unless @tag.discipline == Discipline.find_by(code: "E")
        flash[:warning] = t("flash.tags.tag_discipline",
                            discipline: @tag.discipline.code,
                            resource: Switchboard.model_name.human)
        redirect_back_or_to edit_tag_path(@tag)
        return nil
      end
    else
      @tag.discipline = Discipline.find_by(code: "E")
      @tag.prefix = "EX"
      @tag.tagable_type = "Switchboard"
    end
    setup_form
  end

  # POST /switchboards or /switchboards.json
  def create
    @switchboard = Switchboard.new(switchboard_params.except(:tag))
    authorize @switchboard
    set_tag

    if @tag.nil?
      # @tag is set to nil in set_tag when a security breach attempt is detected.
      tag_nil
      return nil
    else
      if @tag.persisted?
        # Existing tag: Create switchboard and update tag in one transaction using 
        # delegated_type via the delegator (Tag)
        if @switchboard.valid? && @tag.update(tagable: @switchboard)
          @tag.reload
          update_circuits # Create circuits if the :circuits parameter is present
          flash[:success] = t('flash.tagables.assigned_to',
                            resource_name: Switchboard.model_name.human,
                            id: @switchboard.id,
                            tag: @tag.label)
          redirect_to @switchboard
          return
        else
          # Fall through to render :new below
        end
      else
        unless @tag_invalid
          # New tag from tag params:
          # Create both in one transaction using delegated_type via the delegator (Tag)
          begin
            Switchboard.transaction do
              @tag.save!
              @tag.update(tagable: @switchboard)
            end

            update_circuits # Create circuits if the :circuits parameter is present
            flash[:success] = t('flash.tagables.created_and_assigned',
                              resource_name: Switchboard.model_name.human,
                              id: @switchboard.id,
                              tag: @tag.label)
            redirect_to @switchboard
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
                         resource_name: Switchboard.model_name.human.downcase)
    render :new, status: :unprocessable_content
  end

  # GET /switchboards/1/edit
  def edit
    authorize @switchboard

    # Allow edit of switchboard without a tag as a way to rescue orphans: edit with new tag.
    @tag = @switchboard.tag&.present? ? @switchboard.tag : Tag.new(tagable_type: "Switchboard")
    setup_form
  end

  # PATCH/PUT /switchboards/1 or /switchboards/1.json
  def update
    authorize @switchboard
    respond_to do |format|
      begin
        if @switchboard.tag&.persisted?
          # Update existing tag and switchboard
          Switchboard.transaction do
            @tag = @switchboard.tag
            @tag.update!(tag_params)
            @switchboard.update!(switchboard_params.except(:tag))
            update_circuits if params[:circuits].present?
          end
        else
          # Create new tag and associate with switchboard
          authorize Tag, :create?
          Switchboard.transaction do
            @tag = Tag.create!(tag_params)
            @switchboard.update!(switchboard_params.except(:tag))
            update_circuits if params[:circuits].present?
          end
        end
        
        format.html {  
          flash[:success] = t("flash.actions.update.notice", resource_name: Switchboard.model_name.human)
          redirect_to @switchboard 
        }
        format.json { render :show, status: :ok, location: @switchboard }
        
      rescue ActiveRecord::RecordInvalid => e
        setup_form
        flash.now[:alert] = t("flash.actions.update.alert", 
                            resource_name: Switchboard.model_name.human.downcase)
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @switchboard.errors, status: :unprocessable_entity }
      rescue Pundit::NotAuthorizedError => e
        flash[:alert] = e.message
        redirect_to @switchboard
      end
    end
  end

  # DELETE /switchboards/1 or /switchboards/1.json
  def destroy
    authorize @switchboard
    @switchboard.destroy

    respond_to do |format|
      format.html {
        flash[:success] = t('flash.actions.destroy.notice', 
          resource_name: Switchboard.model_name.human)
        redirect_to switchboards_path, status: :see_other
      }
      format.json { head :no_content }
    end
  end

  private

    def set_switchboard
      @switchboard = Switchboard.find(params[:id])
    end

    def setup_form
      @circuits = @switchboard.persisted? ? @switchboard.circuits.count : 0
      @voltage_ratings = Switchboard.voltage_ratings
      @ip_1 = Constants.electrical.ingress_protection.first_digit.to_h
      @ip_2 = Constants.electrical.ingress_protection.second_digit.to_h
      setup_tag_form
    end
    
    # Updates the number of circuits for the switchboard
    # @param [Integer] desired_count - The desired number of circuits
    def update_circuits(desired_count = nil)
      desired_count ||= params.dig(:switchboard, :circuits).presence || params[:circuits].presence
      return unless desired_count
    
      desired_count = desired_count.to_i
      current_count = @switchboard.circuits.count
    
      if desired_count > current_count
        authorize Circuit, :create?
        (desired_count - current_count).times do |i|
          @switchboard.circuits.create(serial: current_count + i + 1)
        end
      elsif desired_count < current_count
        authorize Circuit, :destroy?
        @switchboard.circuits
                   .order(serial: :desc)
                   .limit(current_count - desired_count)
                   .destroy_all
      end
    end

    # Only allow a list of trusted parameters through.
    def switchboard_params
      params.require(:switchboard).permit(:location, :ingress_protection, :voltage_rating,
        :busbar_rating, :busbar_fault_rating, :busbar_fault_duration, 
        :cable_entry, :incomer_protection, :metering, 
        :neutral_bar_connections, :earth_bar_connections, 
        tag: [
          :id, :project_id, :discipline_id, :prefix, :serial, 
          :suffix, :service, :stage, :notes, :tagable_type
        ])
    end

    def tag_nil
    # Tag has been set to nil because tagable set tag routine found a tag that cannot be used to attach a tagable:
    # - not found in the database 
    # - already assigned to a tagable
    # - designated to be assigned to a different class than the calling controller.
    # Workflow should prevent this from being possible through normal use of the application.
      Rails.logger.warn(
        "Forbidden: Invalid tag association - " \
        "Tag: #{@tag&.inspect}, " \
        "Expected type: #{controller_name.classify}, " \
        "User: #{current_user&.id}"
      )
      trap_forbidden
      return
    end
end
