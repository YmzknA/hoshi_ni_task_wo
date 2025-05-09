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
    base_milestone = Milestone.find(params[:id])

    # base_milestoneのユーザーが現在のユーザーと異なる場合は、root_pathにリダイレクト
    return redirect_to root_path unless current_user?(base_milestone.user)

    # base_milestoneのデータで、share_milestoneを作成
    @milestone = LimitedSharingMilestone.new(
      user: base_milestone.user,
      title: base_milestone.title,
      description: base_milestone.description,
      progress: base_milestone.progress,
      color: base_milestone.color,
      start_date: base_milestone.start_date,
      end_date: base_milestone.end_date,
      completed_comment: base_milestone.completed_comment,
      is_on_chart: base_milestone.is_on_chart,
      constellation: base_milestone.constellation
    )

    # base_milestoneのtasksをsharing_milestoneにコピー
    base_milestone.tasks.each do |task|
      sharing_task = LimitedSharingTask.new(
        title: task.title,
        description: task.description,
        progress: task.progress,
        start_date: task.start_date,
        end_date: task.end_date,
        user: task.user
      )
      sharing_task.milestone = @milestone
      @milestone.tasks << sharing_task
    end

    if @milestone.save
      flash.now[:notice] = "共有用の星座が作成されました"
    else
      flash[:alert] = "共有用の星座の作成に失敗しました"
      redirect_to milestone_path(base_milestone) and return
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
