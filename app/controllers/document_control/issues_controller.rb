# frozen_string_literal: true
module DocumentControl
  class IssuesController < ApplicationController
    before_action :authenticate_user!
    before_action :require_project!, only: %i[ new create edit update ]
    before_action :set_issue, only: [:show, :edit, :update, :destroy]
    before_action :set_swatch, only: [:index, :show, :new, :edit]

    # GET /document_control/issues
    def index
      authorize DocumentControl::Issue, :index?
      @q = policy_scope(DocumentControl::Issue).ransack(params[:q])
      @pagy, @issues = pagy(@q.result, limit: 20)
    end

    # GET /document_control/issues/1
    def show
      authorize @issue
    end

    # GET /document_control/issues/new
    def new
      @issue = DocumentControl::Issue.new
      authorize @issue
      setup_form
    end

    # POST /document_control/issues
    def create
      @issue = DocumentControl::Issue.new(issue_params)
      authorize @issue

      if @issue.save
        flash[:success] = t('flash.create.notice', 
          resource_name: @issue.model_name.human)
        set_swatch
        redirect_to @issue
      else
        flash[:alert] = t('flash.create.alert', 
          resource_name: @issue.model_name.human.downcase)
        set_swatch
        render :new, status: :unprocessable_content
      end
    end

    # GET /document_control/issues/1/edit
    def edit
      authorize @issue
      setup_form
    end

    # PATCH/PUT /document_control/issues/1
    def update
      authorize @issue
      if @issue.update(issue_params)
        flash[:success] = t('flash.update.notice', 
          resource_name: @issue.model_name.human)
        set_swatch
        redirect_to @issue
      else
        flash[:alert] = t('flash.update.alert', 
          resource_name: @issue.model_name.human.downcase)
        set_swatch
        render :edit, status: :unprocessable_content 
      end
    end

    # DELETE /document_control/issues/1
    def destroy
      authorize @issue
      if @issue.destroy
        flash[:success] = t('flash.destroy.notice', 
          resource_name: @issue.model_name.human)
      else
        flash[:alert] = t('flash.destroy.alert', 
          resource_name: @issue.model_name.human.downcase)
      end
      set_swatch
      redirect_to document_control_issues_path
    end

    private

      def set_issue
        @issue = DocumentControl::Issue.find(params[:id])
      end

      def set_swatch
        @swatch = DocumentControl::Issue.swatch
      end

      def setup_form
        # Add selector setup here.
      end

      def issue_params
        params.require(:document_control_issue)
        .permit(:document_id, :code, :reason, :source_format_id, :submit)
      end
  end
end
