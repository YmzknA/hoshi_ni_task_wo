class LimitedSharingMilestonesController < ApplicationController
  include GanttChartHelper
  before_action :authenticate_user!, only: [:create]
  before_action :set_milestone, only: [:show, :destroy]
  before_action :validate_another_user, only: [:destroy]

  def show
    @title = "限定公開の星座"
    @is_milestone_completed = (@milestone.progress == "completed")
    @is_not_milestone_on_chart = @milestone.is_on_chart == false

    prepare_for_chart(@milestone) if @milestone.is_on_chart
    @milestone_tasks = @milestone.tasks
  end

  def create
    milestone = Milestone.find(params[:id])
    return redirect_to root_path unless current_user?(milestone.user)

    @sharing_milestone = LimitedSharingMilestone.new(
      user: milestone.user,
      title: milestone.title,
      description: milestone.description,
      progress: milestone.progress,
      color: milestone.color,
      start_date: milestone.start_date,
      end_date: milestone.end_date,
      completed_comment: milestone.completed_comment,
      is_on_chart: milestone.is_on_chart,
      constellation: milestone.constellation
    )

    milestone.tasks.each do |task|
      sharing_task = LimitedSharingTask.new(
        title: task.title,
        description: task.description,
        progress: task.progress,
        start_date: task.start_date,
        end_date: task.end_date,
        user: task.user
      )
      sharing_task.milestone = @sharing_milestone
      @sharing_milestone.tasks << sharing_task
      logger.swim("#{task.id} => #{sharing_task.inspect}")
    end

    if @sharing_milestone.save
      flash.now[:notice] = "共有用の星座が作成されました"
    else
      @sharing_milestone.tasks.each do |task|
        task.errors.full_messages.each do |message|
          logger.swim(message)
        end
      end
      flash[:alert] = "共有用の星座の作成に失敗しました"
      redirect_to milestone_path(milestone) and return
    end
  end

  def destroy
    @milestone.destroy
    flash[:notice] = "共有用の星座が削除されました"
    redirect_to milestones_path, status: :see_other
  end

  private

  def set_milestone
    @milestone = LimitedSharingMilestone.find_by(id: params[:id])

    return if @milestone

    flash[:alert] = "指定された星座が見つかりません"
    redirect_to root_path
  end

  def validate_another_user
    return if current_user?(@milestone.user)

    flash[:alert] = "この星座にはアクセスできません"
    redirect_to root_path
  end

  def prepare_for_chart(milestone)
    # milestone_chartの幅と位置情報を計算
    @milestone_widths, @milestone_lefts = milestone_widths_lefts_hash([milestone])
    @date_range = date_range([milestone])
    @chart_total_width = @milestone_widths[milestone.id].to_i + 40
  end
end
