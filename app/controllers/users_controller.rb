class UsersController < ApplicationController
  def show
    @user = User.find_by(id: params[:id])

    if @user.nil?
      redirect_to root_path, alert: "ユーザが見つかりません"
    else
      @title = "ユーザーページ"

      if current_user?(@user)
        @not_completed_milestones = @user.milestones.where.not(progress: "completed")
        @completed_milestones = @user.milestones.where(progress: "completed")
      else
        @not_completed_milestones = @user.milestones.where(is_public: true).where.not(progress: "completed")
        @completed_milestones = @user.milestones.where(is_public: true).where(progress: "completed")
      end
    end
  end
end
