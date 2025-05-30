class TaskMilestoneAssignmentsController < ApplicationController
  include GanttChartHelper

  before_action :set_milestone
  before_action :authenticate_user!
  before_action :validate_another_user

  def show
    milestone_tasks = @milestone.tasks.start_date_asc
    without_milestone_tasks = current_user.tasks.without_milestone.start_date_asc
    @tasks = milestone_tasks + without_milestone_tasks
  end

  def update
    new_tasks_id_hash = params[:milestone].select { |_, v| v.to_i == 1 }.keys
    new_tasks = current_user.tasks.where(id: new_tasks_id_hash).includes(:milestone)
    success_flag = true # 処理が正常に完了したかどうかのフラグ

    ActiveRecord::Base.transaction do
      success_flag = update_tasks_with_milestone(new_tasks)
      raise ActiveRecord::Rollback unless success_flag
    end

    if success_flag
      prepare_for_chart(@milestone) if @milestone.is_on_chart
      @milestone_tasks = tasks_ransack_result

      flash.now[:notice] = "星座のタスクを更新しました"
    else
      flash.now[:alert] = "星座のタスクの更新に失敗しました"
    end
  end

  private

  def validate_another_user
    return if current_user == @milestone.user

    flash[:alert] = "この星座は他のユーザーのものです。"
    redirect_to root_path
  end

  def set_milestone
    @milestone = Milestone.find(params[:id])
  end

  def update_tasks_with_milestone(tasks)
    # @milestoneを定義してから呼ぶ

    @milestone.tasks = []
    success_flag = true # 処理が正常に完了したかどうかのフラグ

    tasks.each do |task|
      task.milestone = @milestone
      next if task.save

      @milestone.errors.add(:base, "タスク「#{task.title}」の更新に失敗しました")
      task.errors.full_messages.each do |error_message|
        @milestone.errors.add(:base, "「#{task.title}」：#{error_message}")
      end
      success_flag = false
    end
    success_flag
  end

  def tasks_ransack_result
    @q = @milestone.tasks.ransack(params[:q])
    @q.sorts = ["start_date asc", "end_date asc"] if @q.sorts.empty?
    @q.result(distinct: true).includes(:user)
  end

  def prepare_for_chart(milestone)
    return if milestone.start_date.nil? || milestone.end_date.nil?
    return unless milestone.on_chart?

    # milestone_chartの幅と位置情報を計算
    @milestone_widths, @milestone_lefts = milestone_widths_lefts_hash([milestone])
    @date_range = date_range([milestone])
    @chart_total_width = @milestone_widths[milestone.id].to_i + 40
  end
end
