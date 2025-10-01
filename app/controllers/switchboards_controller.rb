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
    setup_form
  end

  # POST /switchboards or /switchboards.json
  def create
    @switchboard = Switchboard.new(switchboard_params)
    authorize @switchboard
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
        if @switchboard.valid? && @tag.update(tagable: @switchboard)
          @tag.reload
          attach_circuits # Create circuits if the :circuits parameter is present
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
              @switchboard.save!
              @tag.tagable = @switchboard
              @tag.save!
            end
            attach_circuits # Create circuits if the :circuits parameter is present
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
  setup_form
end

  # PATCH/PUT /switchboards/1 or /switchboards/1.json
  def update
    authorize @switchboard
    
    respond_to do |format|
      if @switchboard.update(switchboard_params)
          # Handle circuits update if the parameter is present
          if params.dig(:switchboard, :circuits).present?
            current_count = @switchboard.circuits.count
            desired_count = params[:switchboard][:circuits].to_i
            if desired_count > current_count
              # Add new circuits
              (desired_count - current_count).times do |i|
                @switchboard.circuits.create(serial: current_count + i + 1)
              end
            elsif desired_count < current_count
              # Remove circuits
              @switchboard.circuits.order(serial: :asc).limit(current_count - desired_count).destroy_all
            end
          end
        format.html do
          flash[:success] = t("flash.actions.update.notice", resource_name: Switchboard.model_name.human)
          redirect_to @switchboard
        end
        format.json { render :show, status: :ok, location: @switchboard }
      else
        setup_form
        flash.now[:alert] = t("flash.actions.update.alert", resource_name: Switchboard.model_name.human.downcase)
        format.html { render :edit, status: :unprocessable_content }
        format.json { render json: @switchboard.errors, status: :unprocessable_content }
      end
    end
  end

  # DELETE /switchboards/1 or /switchboards/1.json
  def destroy
    authorize @switchboard
    @switchboard.destroy

    respond_to do |format|
      format.html {
        redirect_to switchboards_path,
          status: :see_other,
          notice: t('flash.actions.destroy.notice', resource_name: Switchboard.model_name.human)
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
    end

    def attach_circuits
      if @switchboard.persisted? 
        # Create circuits if the parameter is present
      initial_count = @switchboard.circuits.count
        if params.dig(:switchboard, :circuits).present?
          desired = params[:switchboard][:circuits].to_i
          if desired > initial_count
            authorize(Circuit).create?
            (desired - initial_count).times do |i|
              @switchboard.circuits.create(serial: initial_count + i + 1)
            end
          elsif desired < initial_count
            authorize(Circuit).destroy?
            @switchboard.circuits.order(serial: :asc).limit(initial_count - desired).destroy_all
          end
        end
      end
    end

    # Only allow a list of trusted parameters through.
    def switchboard_params
      params.require(:switchboard).permit(:location, :ingress_protection, :voltage_rating,
        :busbar_rating, :busbar_fault_rating, :busbar_fault_duration, 
        :cable_entry, :incomer_protection, :incomer_metering, 
        :neutral_bar_connections, :earth_bar_connections)
    end
end
