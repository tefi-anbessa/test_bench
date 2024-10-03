class UsersController < ApplicationController
  before_action :authenticate_user!
  after_action :verify_authorized

  def show
    @user = authorize User.find(params[:id])
  end

  def index
    @q = User.ransack(params[:q])
    @pagy, @users = pagy(@q.result, limit: 10)
  end

  private

    def user_params
      params.require(:user).permit(:login)
    end
end
