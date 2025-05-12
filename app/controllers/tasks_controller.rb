class TasksController < ApplicationController
  before_action :set_task, only: [:show, :edit, :update, :update_progress, :destroy]
  before_action :authenticate_user!, except: [:show]
  before_action :ensure_correct_user, only: [:edit, :update, :destroy]
  before_action :set_task_milestone, only: [:update_progress, :update, :destroy]
  before_action :valid_guest_user, only: [:new, :create]

  # GET /tasks or /tasks.json
  def index
    @title = "タスク一覧"
    @user = current_user
    @q = @user.tasks.ransack(params[:q])
    base_tasks = @q.result(distinct: true)

    # 完了したタスク - 作成日の降順
    completed_tasks_set = base_tasks.where(progress: :completed).index_order
    @completed_tasks = completed_tasks_set.reject(&:milestone_completed?)

    # 未完了のタスク - 締切日の昇順（nilを最後に表示）、同じ締切日なら開始日の昇順
    @not_completed_tasks = base_tasks.where.not(progress: :completed).index_order
  end

  # GET /tasks/1
  def show
    # タスク詳細画面に遷移する際、タスクのユーザーがゲストユーザーで、
    # 現在のユーザーがそのタスクのユーザーでない場合は、タスク詳細画面を表示しない
    if @task.user.guest? && !current_user?(@task.user)
      flash[:alert] = "指定されたタスクが見つかりません"
      redirect_to tasks_path
    end

    if @task.milestone&.is_public || current_user?(@task&.user)
      # taskに関連するmilestoneが公開されているか、またはmilestoneのユーザーが現在のユーザーと同じ場合のみ表示
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
      @task_milestone = @task.milestone
      @task_milestone&.update_progress

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
      @task_milestone = @task.milestone
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
    flash.now[:notice] = "タスクを削除しました"
  end

  def update_progress
    if @task.milestone_completed?
      flash.now.alert = "このタスクは完成した星座に関連付けられています"
      redirect_back fallback_location: tasks_path and return
    end

    @task.progress = @task.next_progress

    if @task.save
      @task_milestone&.update_progress
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

  def set_task_milestone
    @task_milestone = @task.milestone if @task.milestone.present?
  end

  def valid_guest_user
    return unless current_user.guest?

    flash[:alert] = "ゲストユーザーはタスクを作成できません"
    redirect_to tasks_path
  end
end
