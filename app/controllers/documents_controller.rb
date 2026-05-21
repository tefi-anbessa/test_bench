# frozen_string_literal: true
  class DocumentsController < ApplicationController
    before_action :authenticate_user!
    before_action :require_project!, only: %i[ new create edit update ]
    before_action :set_discipline, only: [:index, :new, :create]
    before_action :set_document, only: [:show, :edit, :update, :destroy]
    before_action :set_swatch, only: [:index, :show, :new, :edit]

    # GET /documents
    def index
      if @discipline.present?
        authorize @discipline.documents.build()
        @q = @discipline.documents.merge(policy_scope(Document)).ransack(params[:q])
        @pagy, @documents = pagy(@q.result, limit: 20)
      else
        authorize Document
        @q = policy_scope(Document).ransack(params[:q])
        @pagy, @documents = pagy(@q.result, limit: 20)
      end
    end

    # GET /documents/1
    def show
      authorize @document
    end

    # GET /documents/new
    def new
      @document = @discipline.documents.build()
      authorize @document
      setup_form
    end

    # POST /documents
    def create
      @document = @discipline.documents.build(create_params)
      authorize @document

      if @document.save
        flash[:success] = t('flash.create.notice', 
          resource_name: t('activerecord.models.document.one'))
        redirect_to @document
      else
        flash[:alert] = t('flash.create.alert', 
          resource_name: t('activerecord.models.document.one').downcase)
          setup_form
        render :new, status: :unprocessable_content
      end
    end

    # GET /documents/1/edit
    def edit
      authorize @document
      setup_form
    end

    # PATCH/PUT /documents/1
    def update
      authorize @document
      if @document.update(update_params)
        flash[:success] = t('flash.update.notice', 
          resource_name: t('activerecord.models.document.one'))
        redirect_to @document
      else
        flash[:alert] = t('flash.update.alert', 
          resource_name: t('activerecord.models.document.one').downcase)
        setup_form
        set_swatch
        render :edit, status: :unprocessable_content 
      end
    end

    # DELETE /documents/1
    def destroy
      authorize @document
      if @document.destroy
        flash[:success] = t('flash.destroy.notice', 
          count: 1, 
          resource_name: t('activerecord.models.document.one'))
      else
        flash[:alert] = t('flash.destroy.alert', 
          count: 1, 
          resource_name: t('activerecord.models.document.one').downcase)
      end
      redirect_to discipline_documents_path(@discipline)
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

      def set_document
        @document = policy_scope(Document).find_by(id: params[:id])
        raise ApplicationController::ConflictError, :out_of_scope if @document.nil?
        @discipline = @document.discipline
        @issues = @document.issues
      end

      def set_swatch
      @swatch = @discipline&.swatch || @project&.swatch || Swatch.find_by(name: 'app_theme')
      end

      def setup_form
        @doc_types = policy_scope(DocType)
        set_swatch
      end

      def create_params
        params.require(:document)
        .permit(:doc_type_id, :title, :notes)
      end

      def update_params
        params.require(:document)
        .permit(:title, :notes)
      end
  end
