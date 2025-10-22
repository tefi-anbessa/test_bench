class MotorsController < ApplicationController
  include TagablesController
  before_action :authenticate_user!
  before_action :set_motor, only: %i[ show edit update destroy ]

  # GET /motors or /motors.json
  def index
    @q = policy_scope(Motor).ransack(params[:q])
    @pagy, @motors = pagy(@q.result.includes(:tag), limit: 20)
    @orphans = @motors.select{ |motor| motor.tag.nil? }
    @link_errors = current_project.tags.select { |tag| tag.tagable_type == "Motor" && tag.tagable.nil? }
    @link_incomplete = @link_errors.select{ |tag| tag.tagable_id.nil? }
    @link_broken = @link_errors.select{ |tag| !tag.tagable_id.nil? }
    authorize @motors
  end

  # GET /motors/1 or /motors/1.json
  def show
    authorize @motor
  end

  # GET /motors/new
  def new
    authorize @motor = Motor.new()
    set_tag
    setup_form
  end

  # POST /motors or /motors.json
def create
    @motor = Motor.new(motor_params.except(:tag))
    authorize @motor
    set_tag
    unless @motor.valid?
      # Catch invalid motor params and return to new without further processing 
      # Placeholder as motor presently has no validations...
      setup_form
      flash.now[:alert] = t("flash.actions.create.alert",
                           resource_name: Motor.model_name.human.downcase)
      respond_to do |format|
        format.html { render :new, status: :unprocessable_content }
        format.json { render json: @motor.errors, status: :unprocessable_content }
      end
      return
    end
    if @tag.persisted?
      # Existing tag: Create motor and update tag in one transaction using 
      # delegated_type via the delegator (Tag)
      # This relies on @motor being valid, it won't save invalid tagable, 
      # but won't raise an exception either, hence the check above.
      @tag.update(tagable: @motor)
      flash[:success] = t('flash.tagables.assigned_to',
                        resource_name: Motor.model_name.human,
                        id: @motor.id,
                        tag: @tag.label)
      create_success_redirect
      return
    else
      if @tag.errors.none?
        # New tag from tag params:
        # Create both in one transaction using delegated_type via the delegator (Tag)
        begin
          Motor.transaction do
            @tag.save!
            @tag.update(tagable: @motor)
          end
          @tag.reload
          flash[:success] = t('flash.tagables.created_and_assigned',
                            resource_name: Motor.model_name.human,
                            id: @motor.id,
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
                         resource_name: Motor.model_name.human.downcase)
    render :new, status: :unprocessable_content
  end

  # GET /motors/1/edit
  def edit
    authorize @motor

    # Allow edit of motor without a tag as a way to rescue orphans: edit with new tag.
    @tag = @motor.tag&.present? ? @motor.tag : Tag.new(tagable_type: "Motor")
    setup_form
  end

  # PATCH/PUT /motors/1 or /motors/1.json
  def update
    authorize @motor
    @tag = @motor.tag&.present? ? @motor.tag : Tag.new(tag_params.merge(tagable: @motor))
    # Make a dummy motor object for checking motor params
    motor = Motor.new(motor_params.except(:tag))
    unless motor.valid?
      setup_form
      flash.now[:alert] = t("flash.actions.update.alert",
                           resource_name: Motor.model_name.human.downcase)
      render :edit, status: :unprocessable_content
      return
    end
    begin
      if @motor.tag&.persisted?
        # Update existing tag and motor
        Motor.transaction do
          @tag = @motor.tag
          @tag.update!(tag_params)
          @motor.update!(motor_params.except(:tag))
        end
      else
        # Create new tag and associate with motor
        authorize Tag, :create?
        Motor.transaction do
          @tag = Tag.create!(tag_params.merge(tagable: @motor))
          @motor.update!(motor_params.except(:tag))
        end
      end
      flash[:success] = t("flash.actions.update.notice", resource_name: Motor.model_name.human)
      respond_to do |format|
        format.html { redirect_to @motor }
        format.json { render :show, status: :ok, location: @motor }
      end
        
    rescue ActiveRecord::RecordInvalid => e
      setup_form
      flash.now[:alert] = t("flash.actions.update.alert", 
                          resource_name: Motor.model_name.human.downcase)
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @motor.errors, status: :unprocessable_entity }
      end
    rescue Pundit::NotAuthorizedError => e
      flash[:danger] = e.message
      redirect_to @motor
    end
  end

  # DELETE /motors/1 or /motors/1.json
  def destroy
    authorize @motor
    @motor.destroy

    respond_to do |format|
      format.html {
        flash[:success] = t('flash.actions.destroy.notice', 
          resource_name: Motor.model_name.human)
        redirect_to motors_path, status: :see_other
      }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_motor
      @motor = Motor.find(params[:id])
    end

    def setup_form
      if current_project
        @project = current_project
      else
        @project = nil
      end
      @projects = policy_scope(Project)
      @voltage_ratings = Switchboard.voltage_ratings
      @ip_1 = Constants.electrical.ingress_protection.first_digit.to_h
      @ip_2 = Constants.electrical.ingress_protection.second_digit.to_h
      unless @tag&.persisted? # Default tag attributes for motor
        @tag.discipline = Discipline.find_by(code: "E")
        @tag.prefix = "EM"
        @tag.tagable_type = "Motor"
      end
      @disciplines = Discipline.all.select(:id, :code, :name).to_a
    end

    def create_success_redirect
      respond_to do |format|
        format.html { redirect_to @motor }
        format.json { render :show, status: :created, location: @motor }
      end
    end

    # Only allow a list of trusted parameters through.
    def motor_params
      params.require(:motor).permit(:motor_type, :frame_size, :poles, :ingress_protection, :speed_rated, 
        :notes,
        tag: [
          :id, :project_id, :discipline_id, :prefix, :serial, 
          :suffix, :service, :stage, :notes, :tagable_type
        ])
    end
end

