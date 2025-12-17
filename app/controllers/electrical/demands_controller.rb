module Electrical
  class DemandsController < ApplicationController
    before_action :authenticate_user!
    before_action :set_tag, only: %i[new create]
    before_action :set_demand, only: %i[ show edit update destroy ]

    # GET /demands
    def index
      authorize Electrical::Demand
      @q = policy_scope(Electrical::Demand).ransack(params[:q])
      @pagy, @demands = pagy(@q.result.includes(:demandable), limit: 20)
      @demands, @orphans = @demands.partition(&:demandable)
    end

    # GET /demands/1 or /demands/1.json
    def show
      authorize @demand
    end

    # GET /tag/1/demands/new
    def new
      @demand = @tag.tagable.build_electrical_demand()
      authorize @demand
    end

    def create
      @demand = @tag.tagable.build_electrical_demand(demand_params)
      authorize @demand
      if @demand.save
        flash[:success] = I18n.t('flash.create.notice', 
          resource_name: I18n.t('activerecord.models.electrical.demand'))
        redirect_to @demand
        return
      else
        flash.now[:alert] = I18n.t('flash.create.alert', 
          resource_name: I18n.t('activerecord.models.electrical.demand'))
        render 'new', status: :unprocessable_entity
      end
    end

    # GET /demands/1/edit
    def edit
      authorize @demand
      @tag = @demand.tag
    end

    # PATCH/PUT /demands/1 or /demands/1.json
    def update
      authorize @demand
      @tag = @demand.tag
      if @demand.update(demand_params)
        flash[:success] = I18n.t('flash.update.notice', resource_name: I18n.t('activerecord.models.demand'))
        respond_to do |format|
          format.html { redirect_to @demand }
          format.json { render :show, status: :ok, location: @demand }
        end
      else
        flash.now[:alert] = I18n.t('flash.update.alert', resource_name: I18n.t('activerecord.models.demand'))
        respond_to do |format|  
          format.html { render :edit, status: :unprocessable_entity }
          format.json { render json: @demand.errors, status: :unprocessable_entity }
        end
      end
    end

    # DELETE /demands/1 or /demands/1.json
    def destroy
      authorize @demand
      if @demand.destroy
        flash[:success] = I18n.t('flash.destroy.notice', resource_name: I18n.t('activerecord.models.demand'))
      else
        flash.now[:alert] = I18n.t('flash.destroy.alert', resource_name: I18n.t('activerecord.models.demand'))
      end
      respond_to do |format|
        format.html { redirect_to electrical_demands_url, status: :see_other }
        format.json { head :no_content }
      end
    end

    private
      # Use callbacks to share common setup or constraints between actions.
      def set_demand
        @demand = Electrical::Demand.find(params[:id])
        @tag = @demand.tag
      end

      def set_tag
        @tag = Tag.find(params[:tag_id])
        # Trap case when trying to add a demand to a tag that is:
        # - not found in the database 
        # - does not have a tagable
        # - does not have a tagable type that is also demandable
        # Workflow should prevent this from being possible through normal use of the application.
        if @tag.nil? 
          return false
        end
        if @tag.tagable.nil?
          @tag = nil
          return false
        end
        if !Electrical::Demand.demandable_types.include?(@tag.tagable_type)
          @tag = nil
          return false
        end
      end

      # Only allow a list of trusted parameters through.
      def demand_params
        params.require(:electrical_demand).permit(:basis, :config, :supply, :power, :current, :power_factor, 
        :duty, :other_supply, :loadable_type, :loadable_id, :notes)
      end
  end
end