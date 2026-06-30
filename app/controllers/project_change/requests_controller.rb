# frozen_string_literal: true
module ProjectChange
  class RequestsController < ApplicationController
    before_action :authenticate_user!
    before_action :require_project!, only: %i[ new create edit update ]
    before_action :set_project, only: [:index, :new, :create]
    before_action :set_request, only: [:show, :edit, :update, :destroy]
    before_action :set_swatch, only: [:index, :show]

    # GET /change/requests
    def index
      authorize ProjectChange::Request, :index?
      @q = policy_scope(ProjectChange::Request).ransack(params[:q])
      @pagy, @requests = pagy(@q.result, limit: 20)
    end

    # GET /change/requests/1
    def show
      authorize @request
      @neighbours = Navigator.new(scope: @scope, record: @request).neighbours
    end

    # GET /change/requests/new
    def new
      @request = current_project.change_requests.build
      authorize @request
      setup_form
    end

    # POST /change/requests
    def create
      @request = @project.change_requests.build(request_params)
      authorize @request

      if @request.save
        flash[:success] = t('flash.create.notice', 
          resource_name: t("activerecord.models.project_change/request.one"))
        redirect_to @request
      else
        flash[:alert] = t('flash.create.alert',
          resource_name: t("activerecord.models.project_change/request.one").downcase)
        setup_form
        render :new, status: :unprocessable_content
      end
    end

    # GET /change/requests/1/edit
    def edit
      authorize @request
      setup_form
    end

    # PATCH/PUT /change/requests/1
    def update
      authorize @request
      if @request.update(request_params)
        flash[:success] = t('flash.update.notice',
          resource_name: t("activerecord.models.project_change/request.one"))
        redirect_to @request
      else
        flash[:alert] = t('flash.update.alert', 
          resource_name: t("activerecord.models.project_change/request.one").downcase)
        setup_form
        render :edit, status: :unprocessable_content 
      end
    end

    # DELETE /change/requests/1
    def destroy
      authorize @request
      if @request.destroy
        flash[:success] = t('flash.destroy.notice',
          resource_name: t("activerecord.models.project_change/request.one"))
      else
        flash[:alert] = t('flash.destroy.alert', 
          resource_name: t("activerecord.models.project_change/request.one").downcase)
      end
      redirect_to project_project_change_requests_path(@project)
    end

    private

      def set_project
        @project = policy_scope(Project).find_by(id: params[:project_id])
        raise ApplicationController::ConflictError, :out_of_scope if @project.nil?
      end

      def set_request
        @request = policy_scope(ProjectChange::Request).find_by(id: params[:id])
        raise ApplicationController::ConflictError, :out_of_scope if @request.nil?
        @project = @request.project
        @scope = policy_scope(Request).joins(:project)
      end

      def set_swatch
        @swatch = @project.swatch.presence || ProjectChange::Request.swatch
      end

      def setup_form
        @disciplines = policy_scope(Discipline)
        .select('disciplines.id, disciplines.label, disciplines.name')
        .order('disciplines.label ASC')
        set_swatch
      end

      def request_params
        params.require(:project_change_request)
        .permit(:title, :reason, :summary, :duration)
      end
  end
end
