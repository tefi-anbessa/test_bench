# frozen_string_literal: true

class SwatchesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_swatch, only: [:show, :edit, :update, :destroy]

  # GET /swatches
  def index
    authorize Swatch, :index?
    @q = policy_scope(Swatch).ransack(params[:q])
    @pagy, @swatches = pagy(@q.result, limit: 20)
  end

  # GET /swatches/1
  def show
    authorize @swatch
  end

  # GET /swatches/new
  def new
    @swatch = Swatch.new
    authorize @swatch
    setup_form
  end

  # POST /swatches
  def create
    @swatch = Swatch.new(swatch_params)
    authorize @swatch

    if @swatch.save
      flash[:success] = t('flash.create.notice', resource_name: @swatch.model_name.human)
      redirect_to @swatch
    else
      flash[:alert] = t('flash.create.alert', resource_name: @swatch.model_name.human.downcase)
      render :new, status: :unprocessable_content
    end
  end

  # GET /swatches/1/edit
  def edit
    authorize @swatch
    setup_form
  end

  # PATCH/PUT /swatches/1
  def update
    authorize @swatch
    if @swatch.update(swatch_params)
      flash[:success] = t('flash.update.notice', resource_name: @swatch.model_name.human)
      redirect_to @swatch
    else
      flash[:alert] = t('flash.update.alert', resource_name: @swatch.model_name.human.downcase)
      render :edit, status: :unprocessable_content 
    end
  end

  # DELETE /swatches/1
  def destroy
    authorize @swatch
    if @swatch.destroy
      flash[:success] = t('flash.destroy.notice', resource_name: @swatch.model_name.human)
    else
      flash[:alert] = t('flash.destroy.alert', resource_name: @swatch.model_name.human.downcase)
    end
    redirect_to swatches_path
  end

  private

    def set_swatch
      @swatch = Swatch.find(params[:id])
    end

    def setup_form
      # Add selector setup here.
    end

    def swatch_params
      params.require(:swatch)
      .permit(:name, :bg, :text, :form_bg, :form_field, :card_bg, :card_header_bg, :card_border, 
      :badge_bg, :badge_text, :link_text, :link_hover, :submit)
    end
end
