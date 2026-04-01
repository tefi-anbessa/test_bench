# frozen_string_literal: true
module DocumentControl
  class DocTypesController < ApplicationController
    before_action :authenticate_user!
    before_action :require_project!, only: %i[ new create edit update ]
    before_action :set_doc_type, only: [:show, :edit, :update, :destroy]
    before_action :set_swatch, only: [:index, :show, :new, :edit]

    # GET /document_control/doc_types
    def index
      authorize DocumentControl::DocType, :index?
      @q = policy_scope(DocumentControl::DocType).ransack(params[:q])
      @pagy, @doc_types = pagy(@q.result, limit: 20)
    end

    # GET /document_control/doc_types/1
    def show
      authorize @doc_type
    end

    # GET /document_control/doc_types/new
    def new
      @doc_type = DocumentControl::DocType.new
      authorize @doc_type
      setup_form
    end

    # POST /document_control/doc_types
    def create
      debugger
      # Ensure that discipline belongs to current project.
      begin
        @discipline = current_project.disciplines.find(params[:document_control_doc_type][:discipline_id])
      rescue ActiveRecord::RecordNotFound
        # Discipline param provided is not found in current project
        raise ApplicationController::ConflictError, :discipline_not_found
      end
      @doc_type = @discipline.doc_types.build(resource_params)
      authorize @doc_type

      if @doc_type.save
        flash[:success] = t('flash.create.notice', 
          resource_name: @doc_type.model_name.human)
        set_swatch
        redirect_to @doc_type
      else
        flash[:alert] = t('flash.create.alert', 
          resource_name: @doc_type.model_name.human.downcase)
        set_swatch
        setup_form
        render :new, status: :unprocessable_content
      end
    end

    # GET /document_control/doc_types/1/edit
    def edit
      authorize @doc_type
      setup_form
    end

    # PATCH/PUT /document_control/doc_types/1
    def update
      begin
        @discipline = current_project.disciplines.find(params[:document_control_doc_type][:discipline_id])
      rescue ActiveRecord::RecordNotFound
        # Discipline param provided is not found in current project
        raise ApplicationController::ConflictError, :discipline_not_found
      end
      authorize @doc_type
      if @doc_type.update(resource_params)
        flash[:success] = t('flash.update.notice', 
          resource_name: @doc_type.model_name.human)
        set_swatch
        redirect_to @doc_type
      else
        flash[:alert] = t('flash.update.alert', 
          resource_name: @doc_type.model_name.human.downcase)
        set_swatch
        setup_form
        render :edit, status: :unprocessable_content 
      end
    end

    # DELETE /document_control/doc_types/1
    def destroy
      authorize @doc_type
      if @doc_type.destroy
        flash[:success] = t('flash.destroy.notice', 
          resource_name: @doc_type.model_name.human)
      else
        flash[:alert] = t('flash.destroy.alert', 
          resource_name: @doc_type.model_name.human.downcase)
      end
      set_swatch
      redirect_to document_control_doc_types_path
    end

    private

      def set_doc_type
        @doc_type = DocumentControl::DocType.find(params[:id])
      end

      def set_swatch
        @swatch = DocumentControl::DocType.swatch
      end

      def setup_form
        @disciplines = policy_scope(Discipline)
        .select('disciplines.id, disciplines.label, disciplines.name')
        .order('disciplines.label ASC')
      end

      def resource_params
        params.require(:document_control_doc_type)
        .permit(:discipline_id, :code, :label, :description)
      end
  end
end
