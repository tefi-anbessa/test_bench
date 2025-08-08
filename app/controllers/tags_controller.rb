class TagsController < ApplicationController
  before_action :set_tag, only: %i[ show edit update destroy ]
#  before_action :new_params, only: %i[ create update ]
  before_action :authenticate_user!
#  after_action :verify_authorized

  # GET /tags or /tags.json
  def index
    @q = Tag.ransack(params[:q])
    @pagy, @tags = pagy(@q.result.includes(:discipline, :project), limit: 10)
  end

  # GET /tags/1 or /tags/1.json
  def show
  end

  # GET /tags/new
  def new
    @tag = Tag.new
  end

  # GET /tags/1/edit
  def edit
    @role = Role.new
    @users = User.all
  end

  # POST /tags or /tags.json
  def create
    @tag = Tag.new(tag_params)

    respond_to do |format|
      if @tag.save
        format.html { redirect_to @tag, notice: "Tag was successfully created." }
        format.json { render :show, status: :created, location: @tag }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @tag.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /tags/1 or /tags/1.json
  def update
    respond_to do |format|
      if @tag.update(tag_params)
        format.html { redirect_to @tag, notice: "Tag was successfully updated." }
        format.json { render :show, status: :ok, location: @tag }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @tag.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /tags/1 or /tags/1.json
  def destroy
    @tag.destroy

    respond_to do |format|
      format.html { redirect_to tags_path, status: :see_other, notice: "Tag was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    def set_tag
      @tag = Tag.find(params[:id])
    end

    def tag_params
      params.require(:tag).permit(:project_id, :stage, :discipline_id,
                                  :prefix, :new_prefix, :serial, :suffix,
                                  :description, :notes,
                                  :tagable_type, :tagable_id)
    end

    def new_params
      # This has been moved to model callback. Check if a new prefix has been added.
      if params[:tag][:new_prefix].present? && params[:tag][:prefix].empty?
        params[:tag][:prefix] = params[:tag][:new_prefix]
      end
    end

end
