class UsersController < ApplicationController
  def show
    @user = User.find(params[:id])
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
