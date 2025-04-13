class UsersController < ApplicationController
  def show
    @user = User.find_by(id: params[:id])
    if @user.nil?
      redirect_to root_path, alert: "ユーザが見つかりません"
    else
      @title = "ユーザーページ"
    end
  end
end
