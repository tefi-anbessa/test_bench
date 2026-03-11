class TagsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_project!, only: %i[ new create ]
  before_action :set_project
  before_action :set_tag
#  before_action :new_params, only: %i[ create update ]
#  after_action :verify_authorized

  # GET /tags or /tags.json
  def index
    authorize Tag
    @q = policy_scope(Tag).ransack(params[:q])
    @pagy, @tags = pagy(@q.result.includes(discipline: :project), limit: 20)
    @project = current_project
  end

  # GET /tags/1 or /tags/1.json
  def show
    authorize @tag
  end

  # GET /tags/new
  def new
    authorize @tag = Tag.new
    setup_disciplines
    @projects = policy_scope(Project)
  end

  # POST /tags or /tags.json
  def create
    @tag = authorize Tag.new(tag_params)
    if @tag.save
      flash[:success] = I18n.t('flash.create.notice', resource_name: I18n.t('activerecord.models.tag'))
      redirect_to @tag
    else
      flash[:alert] = I18n.t('flash.create.alert', resource_name: I18n.t('activerecord.models.tag'))
      setup_disciplines 
      render :new, status: :unprocessable_content
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
    if @tag.update(tag_params)
      flash[:success] = I18n.t('flash.update.notice', resource_name: I18n.t('activerecord.models.tag'))
      redirect_to @tag
    else
      flash[:alert] = I18n.t('flash.update.alert', 
      resource_name: I18n.t('activerecord.models.tag'))
      setup_disciplines 
      render :edit, status: :unprocessable_content
    end
  end

  # DELETE /tags/1 or /tags/1.json
  def destroy
    authorize @tag
    if @tag.destroy
      flash[:success] = I18n.t('flash.destroy.notice', 
        resource_name: I18n.t('activerecord.models.tag'))
      redirect_to tags_path, status: :see_other
    else
      flash.now[:danger] = I18n.t('flash.destroy.alert', 
        resource_name: I18n.t('activerecord.models.tag'))
      render :show, status: :unprocessable_content
    end
  end

  private

    # [TODO] fix this to allow admin workflow for any project.
    def set_project
      if current_project
        @project = current_project
      else
        @project = nil
        @projects = policy_scope(Project)
      end
    end

    # Setup disciplines for the form selector
    def setup_disciplines
      @disciplines = policy_scope(Discipline)
        .joins(:project)
        .select('projects.code as project_code, disciplines.id, disciplines.label')
        .order('projects.code ASC, disciplines.label ASC')
        .group_by(&:project_code)
        .transform_values { |discs| discs.map { |d| [d.label, d.id] } }
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
      if params[:id].present?
        @tag = Tag.find(params[:id])
      else
        @tag = Tag.new
      end
    end

    def tag_params
      params.require(:tag).permit(:discipline_id, :stage, :prefix, :serial, :suffix,
                                  :service, :location, :notes, :tagable_type, :tagable_id, :submit)
    end


end
