# frozen_string_literal: true
class IssuesController < ApplicationController
  before_action :authenticate_user!
  before_action :require_project!, only: [ :new, :create, :edit, :update ]
  before_action :set_document, only: [ :index, :new, :create ]
  before_action :set_issue, only: [ :show, :edit, :update, :destroy ]
  before_action :set_swatch, only: [ :index, :show ]

  # GET /documents/:document_id/issues
  def index
    authorize @document
    @q = @document.issues.ransack(params[:q])
    @pagy, @issues = pagy(@q.result, limit: 20)
  end

  # GET /issues/1
  def show
    authorize @document
    @neighbours = Navigator.new(scope: @scope, record: @issue).neighbours
  end

  # GET /documents/:document_id/issues/new
  def new
    @issue = @document.issues.build
    authorize @document
    setup_form
  end

  # POST /documents/:document_id/issues
  def create
    @issue = @document.issues.build(issue_params)
    authorize @document

    if @issue.save
      flash[:success] = t('flash.create.notice', 
        resource_name: t('activerecord.models.issue.one'))
      set_swatch
      redirect_to @issue
    else
      flash[:alert] = t('flash.create.alert', 
        resource_name: t('activerecord.models.issue.one').downcase)
      setup_form
      render :new, status: :unprocessable_content
    end
  end

  # GET /issues/1/edit
  def edit
    authorize @document
    setup_form
  end

  # PATCH/PUT /issues/1
  def update
    authorize @document
    if @issue.update(issue_params)
      flash[:success] = t('flash.update.notice', 
        resource_name: t('activerecord.models.issue.one'))
      set_swatch
      redirect_to @issue
    else
      flash[:alert] = t('flash.update.alert', 
        resource_name: t('activerecord.models.issue.one').downcase)
      setup_form
      render :edit, status: :unprocessable_content 
    end
  end

  # DELETE /issues/1
  def destroy
    authorize @document
    if @issue.destroy
      flash[:success] = t('flash.destroy.notice', 
        resource_name: t('activerecord.models.issue.one'))
    else
      flash[:alert] = t('flash.destroy.alert', 
        resource_name: t('activerecord.models.issue.one').downcase)
    end
    set_swatch
    redirect_to document_issues_path(@document)
  end

  private

    def set_document
      @document = policy_scope(Document).find_by(id: params[:document_id])
      raise ApplicationController::ConflictError, :out_of_scope if @document.nil?
      @discipline = @document.discipline
    end

    def set_issue
      @issue = policy_scope(Issue).find_by(id: params[:id])
      raise ApplicationController::ConflictError, :not_found if @issue.nil?
      @document = @issue.document
      raise ApplicationController::ConflictError, :out_of_scope unless policy_scope(Document).include?(@document)
      @discipline = @document.discipline
      @scope = policy_scope(Issue).joins(document: { discipline: :project } ).where(documents: { id: @document.id })
    end

    def set_swatch
      discipline_base = "#{@discipline.name}::Base".safe_constantize
      @swatch = @discipline.swatch || 
                discipline_base&.swatch || 
                Swatch.find_by(name: "app_theme")
    end

    def setup_form
      @source_formats = policy_scope(SourceFormat).order(:vendor, :title, :revision)
      set_swatch
    end

    def issue_params
      params.require(:issue)
      .permit(:code, :reason, :source_format_id)
    end
end
