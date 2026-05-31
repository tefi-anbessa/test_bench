class TagsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_project!, only: %i[ new create edit update]
  before_action :set_discipline, only: %i[ index new create ]
  before_action :set_tag, only: %i[ show edit update destroy ]
  before_action :set_swatch, only: %i[ index show ]

  # GET /tags or /tags.json
  def index
    if @discipline.present?
      authorize @discipline.tags.build()
      @orphans = Tag.where(discipline_id: nil)
      @q = @discipline.tags.merge(policy_scope(Tag)).ransack(params[:q])
      @pagy, @tags = pagy(@q.result.includes(discipline: :project), limit: 20)
    else
      authorize Tag
      @orphans = Tag.where(discipline_id: nil)
      @q = policy_scope(Tag).ransack(params[:q])
      @pagy, @tags = pagy(@q.result, limit: 20)
    end
  end

  # GET /tags/1 or /tags/1.json
  def show
    authorize @tag
  end

  # GET /tags/new
  def new
    authorize @tag = @discipline.tags.build()
    setup_form
  end

  # POST /tags or /tags.json
  def create
    @tag = authorize @discipline.tags.build(tag_params)
    if @tag.save
      flash[:success] = I18n.t('flash.create.notice', resource_name: I18n.t('activerecord.models.tag.one'))
      redirect_to @tag
    else
      flash[:alert] = I18n.t('flash.create.alert', resource_name: I18n.t('activerecord.models.tag.one'))
      setup_form
      render :new, status: :unprocessable_content
    end
  end

  # GET /tags/1/edit
  def edit
    authorize @tag
    setup_form
  end

  # PATCH/PUT /tags/1 or /tags/1.json
  def update
    authorize @tag
    if @tag.update(tag_params)
      flash[:success] = I18n.t('flash.update.notice', resource_name: I18n.t('activerecord.models.tag.one'))
      redirect_to @tag
    else
      flash[:alert] = I18n.t('flash.update.alert', resource_name: I18n.t('activerecord.models.tag.one'))
      setup_form
      render :edit, status: :unprocessable_content
    end
  end

  # DELETE /tags/1 or /tags/1.json
  def destroy
    authorize @tag
    if @tag.destroy
      flash[:success] = I18n.t('flash.destroy.notice', 
        resource_name: I18n.t('activerecord.models.tag.one'))
      redirect_to discipline_tags_path(@discipline)
    else
      flash.now[:danger] = I18n.t('flash.destroy.alert', 
        resource_name: I18n.t('activerecord.models.tag.one'))
      redirect_back fallback_location: project_tags_path(current_project)
    end
    
  end

  private

    def set_discipline
      if params[:discipline_id].present?
        @discipline = policy_scope(Discipline).find_by(id: params[:discipline_id])
        raise ApplicationController::ConflictError, :out_of_scope if @discipline.nil?
        @project = @discipline.project
      elsif params[:project_id].present?
        @discipline = nil
        @project = policy_scope(Project).find_by(id: params[:project_id])
        raise ApplicationController::ConflictError, :out_of_scope if @project.nil?
      end
    end

    def set_tag
      @tag = policy_scope(Tag).find_by(id: params[:id])
      raise ApplicationController::ConflictError, :out_of_scope if @tag.nil?
      @discipline = @tag.discipline
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

    def setup_form
      set_swatch
      @safe_tagable_types = Tag.safe_tagable_types
      @parents = @tag.prospective_parents(policy_scope(Tag)).order(:discipline_id, :full_tag)
    end

    def set_swatch
      @swatch = @discipline&.swatch || @project&.swatch || Swatch.find_by(name: 'app_theme')
    end

    def tag_params
      params.require(:tag).permit(:discipline_id, :stage, :prefix, :serial, :suffix,
                                  :service, :location, :notes, :tagable_type, :parent_id)
    end


end
