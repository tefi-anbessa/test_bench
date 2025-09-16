class TagsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_project
  before_action :set_tag, only: %i[ show edit update destroy ]
#  before_action :new_params, only: %i[ create update ]
#  after_action :verify_authorized

  # GET /tags or /tags.json
  def index
    authorize Tag
    @q = @project.tags.ransack(params[:q])
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
    @tag = authorize Tag.new(tag_params)

    respond_to do |format|
      if @tag.save
        format.html { redirect_to @tag, notice: "Tag was successfully created." }
        format.json { render :show, status: :created, location: @tag }
      else
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
    respond_to do |format|
      if @tag.update(tag_params)
        format.html { redirect_to @tag, notice: "Tag was successfully updated." }
        format.json { render :show, status: :ok, location: @tag }
      else
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

  private

    # [TODO] fix this to allow admin workflow for any project.
    def set_project
      if current_project
        @project = current_project
      else
        redirect_to select_projects_path
      end
    end

    # Setup disciplines for the form selector
    def setup_disciplines
      @disciplines = Discipline.all.select(:id, :code, :name).to_a
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

    def new_params
      # This has been moved to model callback. Check if a new prefix has been added.
      if params[:tag][:new_prefix].present? && params[:tag][:prefix].empty?
        params[:tag][:prefix] = params[:tag][:new_prefix]
      end
    end

end
