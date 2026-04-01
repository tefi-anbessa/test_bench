# frozen_string_literal: true
  class DocumentsController < ApplicationController
    before_action :authenticate_user!
    before_action :require_project!, only: %i[ new create edit update ]
    before_action :set_document, only: [:show, :edit, :update, :destroy]
    before_action :set_swatch, only: [:index, :show, :new, :edit]

    # GET /documents
    def index
      authorize Document, :index?
      @q = policy_scope(Document).ransack(params[:q])
      @pagy, @documents = pagy(@q.result, limit: 20)
    end

    # GET /documents/1
    def show
      authorize @document
    end

    # GET /documents/new
    def new
      @document = Document.new
      authorize @document
      setup_form
    end

    # POST /documents
    def create
      @document = Document.new(create_params)
      authorize @document

      if @document.save
        flash[:success] = t('flash.create.notice', 
          resource_name: @document.model_name.human)
        redirect_to @document
      else
        flash[:alert] = t('flash.create.alert', 
          resource_name: @document.model_name.human.downcase)
          setup_form
          set_swatch
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
      if @document.update(edit_params)
        flash[:success] = t('flash.update.notice', 
          resource_name: @document.model_name.human)
        redirect_to @document
      else
        flash[:alert] = t('flash.update.alert', 
          resource_name: @document.model_name.human.downcase)
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
          resource_name: @document.model_name.human)
      else
        flash[:alert] = t('flash.destroy.alert', 
          resource_name: @document.model_name.human.downcase)
      end
      redirect_to documents_path
    end

    private

      def set_document
        begin
          @document = policy_scope(Document).find(params[:id])
        rescue ActiveRecord::RecordNotFound
          raise Pundit::NotAuthorizedError
        end
        @issues = @document.issues
      end

      def set_swatch
        if @document&.persisted?
          @swatch = @document.discipline.swatch
        else
          @swatch = Document.swatch
        end
      end

      def setup_form
        @disciplines = policy_scope(Discipline)
        .select('disciplines.id, disciplines.label, disciplines.name')
        .order('disciplines.label ASC')
        @doc_types = policy_scope(DocumentControl::DocType)
      end

      def create_params
        params.require(:document)
        .permit(:discipline_id, :doc_type_id, :serial, :title, :notes)
      end

      def edit_params
        params.require(:document)
        .permit(:title, :notes)
      end
  end
