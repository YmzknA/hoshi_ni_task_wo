class GanttChartController < ApplicationController
  include GanttChartHelper
  before_action :authenticate_user!

  def show
    milestones = current_user.milestones.includes(:tasks).on_chart.not_completed.start_date_asc

    if milestones.empty?
      flash[:alert] = "チャートに表示する星座がひとつもありません"
      redirect_to user_path(current_user)
      return
    end

    @chart_presenter = GanttChartPresenter.new(milestones, current_user)
  end

  def milestone_show
    @milestone = current_user.milestones.find(params[:id])
    @milestone_tasks = @milestone.tasks
  end
end
