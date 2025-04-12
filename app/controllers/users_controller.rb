class UsersController < ApplicationController
  def show
    @user = User.find(params[:id])
    @title = "ユーザーページ"
  end
end
