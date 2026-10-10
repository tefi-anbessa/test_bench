class UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_swatch

  def index
    @q = User.ransack(params[:q])
    @pagy, @users = pagy(@q.result)
    authorize @users
  end

  def show
    @user = User.find(params[:id])
    authorize @user
    @scope = policy_scope(User)
    @neighbours = Navigator.new(scope: @scope, record: @user).neighbours
  end

  def edit
    @user = User.find(params[:id])
    authorize @user
  end

  # Profile fields only (job title, time zone, preferred locale, avatar) -
  # see UserPolicy#edit? for why this is a real, Pundit-gated action
  # distinct from Devise's own self-only account/security form.
  def update
    @user = User.find(params[:id])
    authorize @user
    if @user.update(user_params)
      # Keep this request's displayed locale in sync with whatever was just
      # saved, and refresh the cookie so it sticks rather than only taking
      # effect after the next explicit locale switch - see
      # ApplicationController#switch_locale for the read side of this.
      if @user == current_user && user_params[:preferred_locale].present?
        cookies[:locale] = { value: @user.preferred_locale, expires: 1.year.from_now }
      end
      flash[:success] = t('flash.update.notice', resource_name: t('activerecord.models.user.one'))
      redirect_to @user
    else
      flash.now[:alert] = t('flash.update.alert', resource_name: t('activerecord.models.user.one').downcase)
      render :edit, status: :unprocessable_content
    end
  end

  private

    # Users have no project/discipline of their own to theme from - use the
    # same app-wide default swatch every other context-free view falls back
    # to (see e.g. Project.swatch, documents_controller.rb's set_swatch).
    def set_swatch
      @swatch = Swatch.find_by(name: "app_theme")
    end

    def user_params
      params.require(:user).permit(:login, :job_title, :time_zone, :preferred_locale, :avatar)
    end
end
