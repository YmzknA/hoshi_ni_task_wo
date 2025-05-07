module Milestones
  class CopiesController < ApplicationController
    before_action :authenticate_user!
    before_action :set_milestone, only: [:show, :create]

    def show; end

    def create
      @milestone = Milestone.find(params[:id])

      set_date = copy_params[:start_date]
      set_date = @milestone.start_date || @milestone.end_date if set_date.blank?

      @copy = @milestone.copy(set_date)

      @milestone.tasks.each do |task|
        if @milestone.on_chart?
          milestone_task_diff = (task.start_date || task.end_date) - @milestone.start_date
          logger.swim("milestone_task_diff: #{milestone_task_diff}")
          task_set_date = set_date.to_date + milestone_task_diff.days
        else
          task_set_date = task.start_date || task.end_date
        end

        @copy.tasks << task.copy(task_set_date)
      end

      if @copy.save
        flash.now[:notice] = "星座をコピーしました"
        @copy_success = true
      else
        flash.now[:alert] = "星座のコピーに失敗しました"
        @copy_success = false
      end
    end

    private

    def copy_params
      params.require(:milestone).permit(:start_date)
    end

    def set_milestone
      @milestone = Milestone.find(params[:id])
    end
  end
end
