class UsersController < ApplicationController
  before_action :authenticate_user!

  def index
    @q = User.ransack(params[:q])
    @pagy, @users = pagy(@q.result, limit: 10)
    authorize @users
  end

  def show
    @user = User.find(params[:id])
    authorize @user
  end

  private

    def user_params
      params.require(:user).permit(:login)
    end
end
