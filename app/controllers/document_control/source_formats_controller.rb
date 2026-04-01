# frozen_string_literal: true
module DocumentControl
  class SourceFormatsController < ApplicationController
    before_action :authenticate_user!
    before_action :require_project!, only: %i[ new create edit update ]
    before_action :set_source_format, only: [:show, :edit, :update, :destroy]
    before_action :set_swatch, only: [:index, :show, :new, :edit]

    # GET /document_control/source_formats
    def index
      authorize DocumentControl::SourceFormat, :index?
      @q = policy_scope(DocumentControl::SourceFormat).ransack(params[:q])
      @pagy, @source_formats = pagy(@q.result, limit: 20)
    end

    # GET /document_control/source_formats/1
    def show
      authorize @source_format
    end

    # GET /document_control/source_formats/new
    def new
      @source_format = DocumentControl::SourceFormat.new
      authorize @source_format
      setup_form
    end

    # POST /document_control/source_formats
    def create
      @source_format = DocumentControl::SourceFormat.new(resource_params)
      authorize @source_format

      if @source_format.save
        flash[:success] = t('flash.create.notice', 
          resource_name: @source_format.model_name.human)
        set_swatch
        redirect_to @source_format
      else
        flash[:alert] = t('flash.create.alert', 
          resource_name: @source_format.model_name.human.downcase)
        setup_form
        set_swatch
        render :new, status: :unprocessable_content
      end
    end

    # GET /document_control/source_formats/1/edit
    def edit
      authorize @source_format
      setup_form
    end

    # PATCH/PUT /document_control/source_formats/1
    def update
      authorize @source_format
      if @source_format.update(resource_params)
        flash[:success] = t('flash.update.notice', 
          resource_name: @source_format.model_name.human)
        set_swatch
        redirect_to @source_format
      else
        flash[:alert] = t('flash.update.alert', 
          resource_name: @source_format.model_name.human.downcase)
        set_swatch
        setup_form
        render :edit, status: :unprocessable_content 
      end
    end

    # DELETE /document_control/source_formats/1
    def destroy
      authorize @source_format
      if @source_format.destroy
        flash[:success] = t('flash.destroy.notice', 
          resource_name: @source_format.model_name.human)
      else
        flash[:alert] = t('flash.destroy.alert', 
          resource_name: @source_format.model_name.human.downcase)
      end
      set_swatch
      redirect_to document_control_source_formats_path
    end

    private

      def set_source_format
        @source_format = DocumentControl::SourceFormat.find(params[:id])
      end

      def set_swatch
        @swatch = DocumentControl::SourceFormat.swatch
      end

      def setup_form
        # Add selector setup here.
      end

      def resource_params
        params.require(:document_control_source_format)
        .permit(:vendor, :title, :file_extension, :revision, :notes)
      end
  end
end
