class LimitedSharingTasksController < ApplicationController
  before_action :set_task, only: [:show]

  def show; end

  private

  def set_task
    @task = LimitedSharingTask.find(params[:id])
  end
end
