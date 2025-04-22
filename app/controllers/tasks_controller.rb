class TasksController < ApplicationController
  include GanttChartHelper

  before_action :set_task, only: [:show, :edit, :update, :destroy]
  before_action :authenticate_user!, except: [:show]
  before_action :ensure_correct_user, only: [:edit, :update, :destroy]

  # GET /tasks or /tasks.json
  def index
    @title = "タスク一覧"
    @user = current_user
    tasks = @user.tasks.includes(:milestone).order(created_at: :desc)
    @completed_tasks = tasks.where(progress: :completed).reject(&:milestone_completed?)
    @not_completed_tasks = tasks.where.not(progress: :completed)
  end

  # GET /tasks/1
  def show
    if @task.milestone&.is_public || current_user?(@task&.user)
      # taskに関連するmilestoneが公開されているか、またはmilestoneのユーザーが現在のユーザーと同じ場合
    else
      flash[:alert] = "このタスクは非公開です"
      redirect_to tasks_path
    end
  end

  # GET /tasks/new
  # turbo_frameでモーダルを表示
  def new
    @task = Task.new
    if params[:milestone_from_milestone_show].present?
      # マイルストーン詳細画面から遷移した場合
      @from_milestone_show = true
      @milestones = [Milestone.find(params[:milestone_from_milestone_show])]
    else
      # マイルストーン詳細画面から遷移していない場合
      @from_milestone_show = false
      @milestones = current_user.milestones.reject { |m| m.progress == "completed" }
    end
  end

  # GET /tasks/1/edit
  def edit
    @milestones = current_user.milestones.not_completed
  end

  # POST /tasks
  # turbo_streamでモーダルを更新
  def create
    @task = Task.new(task_params)
    user = current_user
    @milestones = user.milestones

    if @task.save
      task_milestone = @task.milestone
      task_milestone&.update_progress

      @task_create_success = true

      flash[:notice] = "タスクを作成しました"
    else
      @task_create_success = false
      @task_new_modal_open = true

      flash.now[:alert] = "タスクの作成に失敗しました"
    end
  end

  # turbo_streamでモーダルを更新している
  def update
    user = current_user
    @milestones = user.milestones

    if @task.update(task_params)
      prepare_for_chart
      # タスクの更新に成功した場合、タスク詳細を表示
      @tasks_show_modal_open = true
      @tasks_update_success = true
      flash.now[:notice] = "タスクを更新しました"
    else
      # タスクの更新に失敗した場合、editモーダルを開いた状態でタスク一覧を表示
      @tasks_edit_modal_open = true
      flash.now[:alert] = "タスクの更新に失敗しました"
    end
  end

  # DELETE /tasks/1
  def destroy
    @task.destroy!
    prepare_for_chart
    flash.now[:notice] = "タスクを削除しました"
  end

  def update_progress
    @task = Task.find(params[:id])

    if @task.milestone_completed?
      flash.now.alert = "このタスクは完成した星座に関連付けられています"
      redirect_back fallback_location: tasks_path and return
    end

    @task.progress = @task.next_progress

    if @task.save
      prepare_for_chart
      task_milestone = @task.milestone
      task_milestone&.update_progress
      flash.now.notice = "タスクの進捗状況を更新しました"
    else
      flash.now.alert = "タスクの進捗状況の更新に失敗しました"
    end
  end

  private

  def set_task
    @task = Task.find(params[:id])
  end

  def task_params
    params.require(:task).permit(:title, :description, :progress,
                                 :start_date, :end_date, :milestone_id).merge(user_id: current_user.id)
  end

  def ensure_correct_user
    task = Task.find(params[:id])

    return if task.user.id == current_user.id

    flash[:alert] = "アクセス権限がありません"
    redirect_to user_path(current_user)
  end

  def prepare_for_chart
    # milestone_chartの幅と位置情報を計算
    on_chart_milestones = current_user.milestones.includes(:tasks).on_chart.not_completed.start_date_asc
    @milestone_widths, @milestone_lefts = milestone_widths_lefts_hash(on_chart_milestones)
    @date_range = date_range(on_chart_milestones)
  end
end
