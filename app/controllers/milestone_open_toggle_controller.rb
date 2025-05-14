class MilestoneOpenToggleController < ApplicationController
  include GanttChartHelper
  before_action :authenticate_user!

  # POST /milestones/1/toggle
  def toggle
    @milestone = Milestone.find(params[:id])
    @milestone.update(is_open: !@milestone.is_open)

    redirect_back(fallback_location: root_path)
  end
end
