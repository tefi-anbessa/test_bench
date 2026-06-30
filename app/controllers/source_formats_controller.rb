# frozen_string_literal: true
class SourceFormatsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_project!, only: %i[ new create edit update ]
  before_action :set_source_format, only: [:show, :edit, :update, :destroy]
  before_action :set_swatch, only: [:index, :show, :new, :edit]

  # GET /source_formats
  def index
    authorize SourceFormat, :index?
    @q = policy_scope(SourceFormat).ransack(params[:q])
    @pagy, @source_formats = pagy(@q.result, limit: 20)
  end

  # GET /source_formats/1
  def show
    authorize @source_format
    @neighbours = Navigator.new(scope: @scope, record: @source_format).neighbours
  end

  # GET /source_formats/new
  def new
    @source_format = SourceFormat.new
    authorize @source_format
    setup_form
  end

  # POST /source_formats
  def create
    @source_format = SourceFormat.new(resource_params)
    authorize @source_format

    if @source_format.save
      flash[:success] = t('flash.create.notice', 
        resource_name: t('activerecord.models.source_format.one'))
      set_swatch
      redirect_to @source_format
    else
      flash[:alert] = t('flash.create.alert', 
        resource_name: t('activerecord.models.source_format.one').downcase)
      setup_form
      set_swatch
      render :new, status: :unprocessable_content
    end
  end

  # GET /source_formats/1/edit
  def edit
    authorize @source_format
    setup_form
  end

  # PATCH/PUT /source_formats/1
  def update
    authorize @source_format
    if @source_format.update(resource_params)
      flash[:success] = t('flash.update.notice', 
        resource_name: t('activerecord.models.source_format.one'))
      set_swatch
      redirect_to @source_format
    else
      flash[:alert] = t('flash.update.alert', 
        resource_name: t('activerecord.models.source_format.one').downcase)
      set_swatch
      setup_form
      render :edit, status: :unprocessable_content 
    end
  end

  # DELETE /source_formats/1
  def destroy
    authorize @source_format
    if @source_format.destroy
      flash[:success] = t('flash.destroy.notice', 
        resource_name: t('activerecord.models.source_format.one'))
    else
      flash[:alert] = t('flash.destroy.alert', 
        resource_name: t('activerecord.models.source_format.one').downcase)
    end
    set_swatch
    redirect_to source_formats_path
  end

  private

    def set_source_format
      @scope = policy_scope(SourceFormat)
      @source_format = @scope.find_by(id: params[:id])
      raise ApplicationController::ConflictError, :out_of_scope if @source_format.nil?
    end

    def set_swatch
      @swatch = SourceFormat.swatch
    end

    def setup_form
      # Add selector setup here.
    end

    def resource_params
      params.require(:source_format)
      .permit(:vendor, :title, :file_extension, :revision, :notes)
    end
end
