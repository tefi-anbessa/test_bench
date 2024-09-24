class UsersController < ApplicationController
  def show
    @user = User.find(params[:id])
  end

  def index
    @pagy, @records = pagy(User.all)
  end

  private

    def user_params
      params.require(:user).permit(:login)
    end
end
