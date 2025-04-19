class TasksController < ApplicationController
  before_action :set_task, only: [:show, :edit, :update, :destroy]
  before_action :authenticate_user!, except: [:show]
  before_action :ensure_correct_user, only: [:edit, :update, :destroy]

  # GET /tasks or /tasks.json
  def index
    @title = "タスク一覧"
    @user = current_user
    @task = Task.new
    @milestones = @user.milestones
    @tasks = @user.tasks.includes(:milestone).order(created_at: :desc)
    @completed_tasks = @tasks.where(progress: :completed)
    @not_completed_tasks = @tasks.where.not(progress: :completed)
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
      @milestones = current_user.milestones
    end
  end

  # GET /tasks/1/edit
  def edit
    @milestones = current_user.milestones
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
      # タスクの更新に成功した場合、タスク詳細を表示
      @tasks_show_modal_open = true
      flash.now[:notice] = "タスクを更新しました"
    else
      # タスクの更新に失敗した場合、editモーダルを開いた状態でタスク一覧を表示
      @tasks_edit_modal_open = true
      flash.now[:alert] = "タスクの更新に失敗しました"
    end
  end

  # DELETE /tasks/1 or /tasks/1.json
  def destroy
    @task.destroy!

    respond_to do |format|
      format.html { redirect_to tasks_path, status: :see_other, notice: "Task was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  def update_progress
    @task = Task.find(params[:id])
    @task.progress = if @task.progress == "not_started"
                       "in_progress"
                     elsif @task.progress == "in_progress"
                       "completed"
                     else
                       "not_started"
                     end

    if @task.save
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
end
