class TagsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_project
  before_action :set_tag, only: %i[ show edit update destroy ]
#  before_action :new_params, only: %i[ create update ]
#  after_action :verify_authorized

  # GET /tags or /tags.json
  def index
    authorize Tag
    @q = policy_scope(Tag).ransack(params[:q])
    @pagy, @tags = pagy(@q.result.includes(:discipline, :project), limit: 10)
  end

  # GET /tags/1 or /tags/1.json
  def show
    authorize @tag
  end

  # GET /tags/new
  def new
    authorize @tag = Tag.new
    setup_disciplines
  end

  # POST /tags or /tags.json
  def create
    combine_prefix_parts
    @tag = authorize Tag.new(tag_params)

    respond_to do |format|
      if @tag.save
        format.html { redirect_to @tag, notice: "Tag was successfully created." }
        format.json { render :show, status: :created, location: @tag }
      else
        setup_disciplines 
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @tag.errors, status: :unprocessable_entity }
      end
    end
  end

  # GET /tags/1/edit
  def edit
    authorize @tag
    setup_disciplines
  end

  # PATCH/PUT /tags/1 or /tags/1.json
  def update
    authorize @tag
    combine_prefix_parts
    respond_to do |format|
      if @tag.update(tag_params)
        format.html { redirect_to @tag, notice: "Tag was successfully updated." }
        format.json { render :show, status: :ok, location: @tag }
      else
        setup_disciplines 
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @tag.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /tags/1 or /tags/1.json
  def destroy
    authorize @tag
    @tag.destroy

    respond_to do |format|
      format.html { redirect_to tags_path, status: :see_other, notice: "Tag was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  # GET /tags/schema_data
  def schema_data
    discipline_id = params[:discipline_id]
    return render json: {} unless discipline_id.present?
    schema_data = Tag.schema_for_form(discipline_id)
    respond_to do |format|
      format.json { render json: schema_data }
      format.any { render json: schema_data }
    end
  end

  private

    # [TODO] fix this to allow admin workflow for any project.
    def set_project
      if current_project
        @project = current_project
      else
        redirect_to select_projects_path
      end
      @projects = policy_scope(Project)
    end

    # Setup disciplines for the form selector
    def setup_disciplines
      @disciplines = Discipline.all.select(:id, :code, :name).to_a
    end

    def combine_prefix_parts
      return unless isa51_schema?
      
      parts = [
        params[:tag][:measured_variable],
        params[:tag][:modifier],
        params[:tag][:function], 
        params[:tag][:modifier_function]
      ].compact
      
      params[:tag][:prefix] = parts.join('') if parts.any?
    end

    def isa51_schema?
      discipline_id = params[:tag][:discipline_id]
      return false unless discipline_id.present?
      
      discipline_data = Constants.tag.discipline.send(
        Tag.normalize_discipline_code(discipline_id)
      ) rescue nil
      
      return false unless discipline_data
      discipline_data[:prefix_schema] == :isa51
    end

    def set_tag
      @tag = Tag.find(params[:id])
    end

    def tag_params
      params.require(:tag).permit(:project_id, :stage, :discipline_id,
                                  :prefix, :new_prefix, :serial, :suffix,
                                  :service, :notes,
                                  :tagable_type, :tagable_id)
    end


end
