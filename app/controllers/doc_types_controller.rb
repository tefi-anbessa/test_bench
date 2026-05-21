# frozen_string_literal: true
class DocTypesController < ApplicationController
  before_action :authenticate_user!
  before_action :require_project!, only: %i[ new create edit update ]
  before_action :set_discipline, only: %i[ index new create ]
  before_action :set_doc_type, only: [:show, :edit, :update, :destroy]
  before_action :set_swatch, only: [:index, :show ]

  # GET /disciplines/:discipline_id/doc_types
  def index
    if @discipline.present?
      authorize @discipline.doc_types.build()
      @q = @discipline.doc_types.merge(policy_scope(DocType)).ransack(params[:q])
      @pagy, @doc_types = pagy(@q.result, limit: 20)
    else
      authorize DocType
      @q = policy_scope(DocType).ransack(params[:q])
      @pagy, @doc_types = pagy(@q.result, limit: 20)
    end
  end

  # GET /doc_types/1
  def show
    authorize @doc_type
  end

  # GET /disciplines/:discipline_id/doc_types/new
  def new
    @doc_type = @discipline.doc_types.build()
    authorize @doc_type
    setup_form
  end

  # POST /disciplines/:discipline_id/doc_types
  def create
    @doc_type = @discipline.doc_types.build()
    authorize @doc_type
    # Doc_type has a copy_from facility to allow selecting any other existing
    # doc_type as a template. Does not cater for enum checking.
    set_attributes
    if @doc_type.save
      flash[:success] = t('flash.create.notice', 
        resource_name: t("activerecord.models.doc_type.one"))
      redirect_to @doc_type
    else
      flash[:alert] = t('flash.create.alert', 
        resource_name: t("activerecord.models.doc_type.one").downcase)
      setup_form
      render :new, status: :unprocessable_content
    end
  end

  # GET /doc_types/1/edit
  def edit
    authorize @doc_type
    setup_form
  end

  # PATCH/PUT /doc_types/1
  def update
    authorize @doc_type
    # Doc_type has a copy_from facility to allow selecting any other existing
    # doc_type as a template. Does not cater for enum checking.
    set_attributes
    if @doc_type.save
      flash[:success] = t('flash.update.notice', 
        resource_name: t("activerecord.models.doc_type.one"))
      redirect_to @doc_type
    else
      flash[:alert] = t('flash.update.alert', 
        resource_name: t("activerecord.models.doc_type.one").downcase)
      setup_form
      render :edit, status: :unprocessable_content 
    end
  end

  # DELETE /doc_types/1
  def destroy
    authorize @doc_type
    if @doc_type.destroy
      flash[:success] = t('flash.destroy.notice', 
        resource_name: t("activerecord.models.doc_type.one"))
    else
      flash[:alert] = t('flash.destroy.alert', 
        resource_name: t("activerecord.models.doc_type.one").downcase)
    end
    redirect_to discipline_doc_types_path(@discipline)
  end

  private

    def set_discipline
      if params[:discipline_id].present?
        @discipline = policy_scope(Discipline).find_by(id: params[:discipline_id])
        raise ApplicationController::ConflictError, :out_of_scope if @discipline.nil?
      elsif params[:project_id].present?
        @discipline = nil
        @project = policy_scope(Project).find_by(id: params[:project_id])
        raise ApplicationController::ConflictError, :out_of_scope if @project.nil?
      end
    end

    def set_doc_type
      @doc_type = policy_scope(DocType).find_by(id: params[:id])
      raise ApplicationController::ConflictError, :out_of_scope if @doc_type.nil?
      @discipline = @doc_type.discipline
    end

    def set_attributes
      @template = DocType.find_by(id: params[:copy_from]) if params[:copy_from].present?
      template_attrs = @template ? @template.attributes.slice(*resource_params.except(:copy_from).keys) : {}
      @doc_type.assign_attributes(template_attrs.merge(resource_params.except(:copy_from)))
    end

    def set_swatch
      @swatch = @discipline&.swatch || @project&.swatch || DocType.swatch || Swatch.find_by(name: 'app_theme')
    end

    def setup_form
      @copy_from_selector = DocType
        .select(:code, :name)
        .distinct
        .order(:code, :name)
      set_swatch
    end

    def resource_params
      params.require(:doc_type)
      .permit(:code, :name, :description)
    end
end
