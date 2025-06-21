class TasksController < ApplicationController
  before_action :set_task, only: [:edit, :update, :update_progress, :destroy]
  before_action :authenticate_user!, except: [:autocomplete]
  before_action :ensure_correct_user, only: [:edit, :update, :destroy]
  before_action :set_task_milestone, only: [:update_progress, :update, :destroy]
  before_action :valid_guest_user, only: [:create]

  def index
    @task = Task.new
    @milestones = current_user.milestones.not_completed
    @title = "タスク一覧"
    @user = current_user
    base_tasks = ransack_result

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
    @milestones = if params[:milestone_id]
                    user.milestones.where(id: params[:milestone_id])
                  else
                    user.milestones
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
    user = current_user
    @milestones = user.milestones

    if @task.update(task_params)
      # タスクの更新に成功した場合、タスク詳細を表示

      update_task_milestone_and_load_tasks

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
  def update_progress
    if @task.milestone_completed?
      flash.now.alert = "このタスクは完成した星座に関連付けられています"
      redirect_back fallback_location: tasks_path and return
    end

    @task.progress = @task.next_progress

    if @task.save
      update_task_milestone_and_load_tasks
      flash.now.notice = "タスクの進捗状況を更新しました"
    else
      flash.now.alert = "タスクの進捗状況の更新に失敗しました"
    end
  end

  # タスクのautocomplete機能, stimulus_autocompleteで使用
  def autocomplete
    id = params[:milestone_id] # optional
    @milestone = Milestone.find_by(id: id) # idが存在しない場合はnil
    progress = params[:progress] # optional
    query = ActiveRecord::Base.sanitize_sql_like(params[:q])

    @tasks = if @milestone.present? && (current_user?(@milestone.user) || @milestone.public?)
               # milsestone_idが指定されている場合
               search_milestone_tasks(query, @milestone)
             elsif progress.present?
               # progressが指定されている場合
               # progress = "not_completed" || progressのenum値
               search_tasks_by_progress(query, progress)
             else
               search_tasks_by_title(query)
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
                                 :start_date, :end_date, :milestone_id).merge(user_id: current_user.id)
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

  def sort_tasks_by_complete_and_start_date(tasks)
    # 完了したタスクを後ろにして、それぞれ開始日でソート
    not_completed_tasks = tasks.not_completed.start_date_asc
    completed_tasks = tasks.completed.start_date_asc
    not_completed_tasks + completed_tasks
  end

  def update_task_milestone_and_load_tasks
    return unless @task_milestone.present?

    # 星座の進捗をタスクの進捗に合わせて更新
    @task_milestone.update_progress

    set_chart_tasks
  end

  def set_chart_tasks
    return unless @task_milestone.on_chart?

    tasks = if current_user.completed_tasks_hidden?
              @task_milestone.tasks.not_completed.valid_dates_nil
            else
              @task_milestone.tasks.valid_dates_nil
            end

    @chart_tasks = sort_tasks_by_complete_and_start_date(tasks).to_a

    # いま処理しているタスクがまだdbに存在していればチャートに表示するために追加している
    current_task = @task_milestone.tasks.find_by(id: @task.id)
    @chart_tasks << current_task if current_task && @chart_tasks.exclude?(current_task)
  end

  def ransack_result
    @q = @user.tasks.ransack(params[:q])
    @q.sorts = ["start_date asc", "end_date asc"] if @q.sorts.empty?
    @q.result(distinct: true).includes(:milestone)
  end

  def search_tasks_by_title(query)
    # タスクのautocomplete機能で使用
    q = current_user.tasks.ransack("title_cont" => query)
    q.sorts = ["start_date asc", "end_date asc"] if q.sorts.empty?
    q.result(distinct: true).includes(:milestone)
  end

  def search_milestone_tasks(query, milestone)
    # マイルストーン詳細画面からタスクのautocomplete機能を使用する場合
    q = milestone.tasks.ransack("title_cont" => query)
    q.sorts = ["start_date asc", "end_date asc"] if q.sorts.empty?
    q.result(distinct: true).includes(:milestone)
  end

  def search_tasks_by_progress(query, progress)
    tasks = search_tasks_by_title(query)
    if progress == "not_completed"
      # 未完了のタスクを取得
      tasks.not_completed
    else
      tasks.where(progress: progress)
    end
  end
end
