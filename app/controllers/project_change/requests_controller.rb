# frozen_string_literal: true
module ProjectChange
  class RequestsController < ApplicationController
    before_action :authenticate_user!
    before_action :require_project!, only: %i[ new create edit update ]
    before_action :set_request, only: [:show, :edit, :update, :destroy]
    before_action :set_swatch, only: [:index, :show, :new, :edit]

    # GET /change/requests
    def index
      authorize ProjectChange::Request, :index?
      @q = policy_scope(ProjectChange::Request).ransack(params[:q])
      @pagy, @requests = pagy(@q.result, limit: 20)
    end

    # GET /change/requests/1
    def show
      authorize @request
    end

    # GET /change/requests/new
    def new
      @request = current_project.change_requests.build
      authorize @request
      setup_form
    end

    # POST /change/requests
    def create
      @request = current_project.change_requests.build(request_params)
      authorize @request

      if @request.save
        flash[:success] = t('flash.create.notice', 
          resource_name: @request.model_name.human)
        set_swatch
        redirect_to @request
      else
        flash[:alert] = t('flash.create.alert', 
          resource_name: @request.model_name.human.downcase)
        set_swatch
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
          resource_name: @request.model_name.human)
        set_swatch
        redirect_to @request
      else
        flash[:alert] = t('flash.update.alert', 
          resource_name: @request.model_name.human.downcase)
        set_swatch
        render :edit, status: :unprocessable_content 
      end
    end

    # DELETE /change/requests/1
    def destroy
      authorize @request
      if @request.destroy
        flash[:success] = t('flash.destroy.notice', 
          resource_name: @request.model_name.human)
      else
        flash[:alert] = t('flash.destroy.alert', 
          resource_name: @request.model_name.human.downcase)
      end
      set_swatch
      redirect_to project_change_requests_path
    end

    private

      def set_request
        begin
          @request = policy_scope(ProjectChange::Request).find(params[:id])
        rescue ActiveRecord::RecordNotFound
          raise Pundit::NotAuthorizedError
        end
      end

      def set_swatch
        @swatch = ProjectChange::Request.swatch
      end

      def setup_form
        @disciplines = policy_scope(Discipline)
        .select('disciplines.id, disciplines.label, disciplines.name')
        .order('disciplines.label ASC')
      end

      def request_params
        params.require(:project_change_request)
        .permit(:title, :reason, :summary, :duration)
      end
  end
end
