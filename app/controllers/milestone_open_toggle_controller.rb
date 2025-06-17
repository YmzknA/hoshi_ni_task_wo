class MilestoneOpenToggleController < ApplicationController
  before_action :authenticate_user!

  def toggle
    @milestone = Milestone.find(params[:id])

    if @milestone.update(is_open: !@milestone.is_open)
      # dont
    else
      flash[:alert] = "星座の開閉に失敗しました。"
    end

    redirect_back(fallback_location: root_path)
  end
end
