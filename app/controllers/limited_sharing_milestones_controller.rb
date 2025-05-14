class LimitedSharingMilestonesController < ApplicationController
  include GanttChartHelper
  before_action :authenticate_user!, only: [:create]
  before_action :set_milestone, only: [:show, :destroy]
  before_action :validate_another_user, only: [:destroy]

  def show
    @title = "限定公開の星座"

    prepare_meta_tags(@milestone)
    prepare_for_chart(@milestone) if @milestone.is_on_chart
    @milestone_tasks = @milestone.tasks
  end

  def create
    base_milestone = Milestone.find(params[:id])

    # base_milestoneのユーザーが現在のユーザーと異なる場合は、root_pathにリダイレクト
    return redirect_to root_path unless current_user?(base_milestone.user)

    # base_milestoneのデータで、share_milestoneを作成
    @milestone = generate_limited_sharing_milestone(base_milestone)

    # base_milestoneのtasksをsharing_milestoneにコピー
    base_milestone.tasks.each do |base_task|
      task = generate_limited_sharing_task(base_task)
      task.milestone = @milestone
      @milestone.tasks << task
    end

    if @milestone.save
      flash[:notice] = "共有用の星座が作成されました"
      redirect_to share_milestone_path(@milestone) and return
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

  def generate_limited_sharing_milestone(base_milestone)
    LimitedSharingMilestone.new(
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
  end

  def generate_limited_sharing_task(base_task)
    LimitedSharingTask.new(
      title: base_task.title,
      description: base_task.description,
      progress: base_task.progress,
      start_date: base_task.start_date,
      end_date: base_task.end_date,
      user: base_task.user
    )
  end

  def prepare_for_chart(milestone)
    # milestone_chartの幅と位置情報を計算
    @milestone_widths, @milestone_lefts = milestone_widths_lefts_hash([milestone])
    @date_range = date_range([milestone])
    @chart_total_width = @milestone_widths[milestone.id].to_i + 40
  end

  def prepare_meta_tags(milestone)
    set_meta_tags og: {
      title: milestone.title,
      description: "#{milestone.title}の限定公開ページです。",
      url: share_milestone_url(milestone)
    }
  end
end
