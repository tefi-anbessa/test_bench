module Electrical
  class DemandsController < ApplicationController
    before_action :authenticate_user!
    before_action :set_tag, only: %i[new create]
    before_action :set_discipline, only: %i[index]
    before_action :set_demand, only: %i[ show edit update destroy ]
    before_action :set_swatch, only: %i[index show new edit]

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
      @neighbours = Navigator.new(scope: @scope, record: @demand).neighbours
    end

    # GET /tag/1/demands/new
    def new
      @demand = @tag.tagable.build_electrical_demand()
      authorize @demand
    end

    def create
      @demand = @tag.tagable.build_electrical_demand(demand_params.except(:other_supply))
      authorize @demand
      if @demand.save
        flash[:success] = I18n.t('flash.create.notice', 
          resource_name: I18n.t('activerecord.models.electrical/demand.one'))
        redirect_to @demand
        return
      else
        set_swatch
        flash.now[:alert] = I18n.t('flash.create.alert', 
          resource_name: I18n.t('activerecord.models.electrical/demand.one'))
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
      if @demand.update(demand_params)
        flash[:success] = I18n.t('flash.update.notice', resource_name: I18n.t('activerecord.models.electrical/demand.one'))
        redirect_to @demand
      else
        set_swatch
        flash.now[:alert] = I18n.t('flash.update.alert', resource_name: I18n.t('activerecord.models.electrical/demand.one'))
        render :edit, status: :unprocessable_entity
      end
    end

    # DELETE /demands/1 or /demands/1.json
    def destroy
      authorize @demand
      if @demand.destroy
        flash[:success] = I18n.t('flash.destroy.notice', resource_name: I18n.t('activerecord.models.electrical/demand.one'))
      else
        flash.now[:alert] = I18n.t('flash.destroy.alert', resource_name: I18n.t('activerecord.models.electrical/demand.one'))
      end
      redirect_to discipline_electrical_demands_url(@discipline), status: :see_other
    end

    private

      def set_discipline
        @discipline = policy_scope(Discipline).find_by(id: params[:discipline_id])
        raise ApplicationController::ConflictError, :out_of_scope if @discipline.nil?
      end

      def set_demand
        @demand = policy_scope(Electrical::Demand).find_by(id: params[:id])
        raise ApplicationController::ConflictError, 
          :out_of_scope if @demand.nil?
        if @demand.demandable.present? && @demand.demandable.tag.present?
          @tag = @demand.tag
        else
          raise ApplicationController::ConflictError, 
            :record_is_orphan
        end
        @discipline = @demand.demandable.tag.discipline
        @scope = policy_scope(Electrical::Demand)
      end

      def set_tag
        @tag = policy_scope(Tag).find_by(id: params[:tag_id])
        raise ApplicationController::ConflictError, 
          :tag_not_found if @tag.nil?
        raise ApplicationController::ConflictError, 
          :tagable_not_set if @tag.tagable.nil?
        raise ApplicationController::ConflictError, 
          :tag_not_demandable unless Electrical::Demand.demandable_types.include?(@tag.tagable.class.name)
        raise ApplicationController::ConflictError, 
          :tag_already_assigned if @tag.tagable.electrical_demand.present?
        @discipline = @tag.discipline
      end

      def set_swatch
        @swatch = Electrical::Demand.swatch
      end

      # Only allow a list of trusted parameters through.
      def demand_params
        params.require(:electrical_demand).permit(:basis, :basis_notes, :config, :supply, :power, :current, :power_factor, 
        :duty, :other_supply, :loadable_type, :loadable_id, :notes)
      end
  end
end