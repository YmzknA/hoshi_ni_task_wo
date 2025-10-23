class TasksController < ApplicationController
  include SearchConcern
  include ChartUpdateConcern

  before_action :set_task, only: [:edit, :update, :destroy]
  before_action :authenticate_user!, except: [:autocomplete]
  before_action :ensure_correct_user, only: [:edit, :update, :destroy]
  before_action :set_task_milestone, only: [:update, :destroy]
  before_action :valid_guest_user, only: [:create]

  def index
    @task = Task.new
    @milestones = current_user.milestones.not_completed
    @title = "タスク一覧"
    @user = current_user
    base_tasks = ransack_by_title_and_description("task")

    # 完了したタスク - 作成日の降順
    @completed_tasks = base_tasks.completed.reject(&:milestone_completed?)

    # 未完了のタスク - 締切日の昇順（nilを最後に表示）、同じ締切日なら開始日の昇順
    @not_completed_tasks = base_tasks.not_completed.reject(&:milestone_completed?)
  end

  def edit
    @milestones = current_user.milestones.not_completed
  end

  # turbo_streamで更新
  def create
    @task = Task.new(task_params)
    user = current_user

    # params[:milestone_id]が存在する場合（milestone_showからのアクセス）
    @from_milestone_show = params[:milestone_id].present?
    @milestones = if @from_milestone_show
                    user.milestones.where(id: params[:milestone_id])
                  else
                    user.milestones.not_completed
                  end

    if @task.save
      @task_milestone = @task.milestone

      update_task_milestone_and_load_tasks

      @task_create_success = true
      flash.now[:notice] = "タスクを作成しました"
    else
      @task_new_modal_open = true

      flash.now[:alert] = "タスクの作成に失敗しました"
    end
  end

  # turbo_stream更新している
  def update
    @milestones = current_user.milestones.not_completed
    @previous_milestone = @task.milestone

    if @task.update(task_params)
      # タスクの更新に成功した場合、タスク詳細を表示
      update_task_milestone_and_load_tasks
      setup_chart_update_data
      @tasks_show_modal_open = true
      @tasks_update_success = true
      flash.now[:notice] = "タスクを更新しました"
    else
      # タスクの更新に失敗した場合、editモーダルを開いた状態でタスク一覧を表示
      @base_task = Task.find_by(id: params[:id])
      @tasks_edit_modal_open = true
      flash.now[:alert] = "タスクの更新に失敗しました"
    end
  end

  def destroy
    @task.destroy!

    update_task_milestone_and_load_tasks
    flash.now[:notice] = "タスクを削除しました"
  end

  # #################################
  # CRUD以外のアクション
  # ###########################################

  # タスクのautocomplete機能, stimulus_autocompleteで使用
  def autocomplete
    id = params[:milestone_id] # optional
    @milestone = Milestone.find_by(id: id) # idが存在しない場合はnil
    progress = params[:progress] # optional

    @tasks = if @milestone.present? && (current_user?(@milestone.user) || @milestone.public?)
               # milsestone_idが指定されている場合
               # progress = "not_completed" || "completed" || その他
               autocomplete_tasks_from_milestone(@milestone, progress)
             elsif progress.present?
               # progressだけが指定されている場合
               # progress = "not_completed" || その他
               ransack_by_title_with_progress(progress)
             else
               autocomplete_by_title("task")
             end

    # @tasksの中でタイトルが他のものと同じものを一つに
    @tasks = @tasks.group_by(&:title).map { |_, tasks| tasks.first }
  end

  # ##################################
  # privateメソッド
  # ############################################
  private

  def set_task
    @task = Task.find(params[:id])
  end

  def task_params
    params.require(:task).permit(:title, :description, :progress,
                                 :start_date, :end_date, :milestone_id, :from_chart).merge(user_id: current_user.id)
  end

  def set_task_milestone
    @task_milestone = @task.milestone if @task.milestone.present?
  end

  def ensure_correct_user
    task = Task.find(params[:id])

    return if task.user.id == current_user.id

    flash[:alert] = "アクセス権限がありません"
    redirect_to user_path(current_user)
  end

  def valid_guest_user
    return unless current_user.guest?

    flash[:alert] = "ゲストユーザーはタスクを作成できません"
    redirect_to tasks_path
  end

  def update_task_milestone_and_load_tasks
    # 変更前の星座も更新
    @previous_milestone&.update_progress

    return unless @task_milestone.present?

    # 新しい星座も更新
    @task_milestone.update_progress

    set_chart_tasks
  end
end
