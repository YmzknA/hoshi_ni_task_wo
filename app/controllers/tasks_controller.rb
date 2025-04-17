class TasksController < ApplicationController
  before_action :set_task, only: [:show, :edit, :update, :destroy]
  before_action :authenticate_user!
  before_action :ensure_correct_user, only: [:edit, :update, :destroy]

  # GET /tasks or /tasks.json
  def index
    @title = "タスク一覧"
    @user = current_user
    @task = Task.new
    @milestones = @user.milestones
    @tasks = @user.tasks.includes(:milestone).order(created_at: :desc)
    @not_started_tasks = @tasks.where(progress: :not_started)
    @in_progress_tasks = @tasks.where(progress: :in_progress)
    @completed_tasks = @tasks.where(progress: :completed)
    @not_completed_tasks = @tasks.where.not(progress: :completed)
  end

  # GET /tasks/1 or /tasks/1.json
  def show
    if @task.milestone&.is_public || current_user?(@task&.user)
      # taskに関連するmilestoneが公開されているか、またはmilestoneのユーザーが現在のユーザーと同じ場合
    else
      flash[:alert] = "このタスクは非公開です"
      redirect_to user_check_path
    end
  end

  # GET /tasks/new
  def new
    @user = current_user
    @task = Task.new
    @milestones = @user.milestones
  end

  # GET /tasks/1/edit
  def edit; end

  # POST /tasks or /tasks.json
  def create
    @task = Task.new(task_params)

    if @task.save
      task_milestone = @task.milestone
      task_milestone&.update_progress

      flash[:notice] = "タスクを作成しました"
      redirect_to tasks_path
    else
      # タスクの作成に失敗した場合、モーダルを開いた状態でタスク一覧を表示
      # indexをrenderすることで、@taskがnilにならないようにする
      # indexに渡すインスタンス変数は、@taskを除いてすべて同じ
      @task_new_modal_open = true
      @user = current_user
      @milestones = @user.milestones
      @tasks = @user.tasks.includes(:milestone).order(created_at: :desc)
      @not_started_tasks = @tasks.where(progress: :not_started)
      @in_progress_tasks = @tasks.where(progress: :in_progress)
      @completed_tasks = @tasks.where(progress: :completed)
      @not_completed_tasks = @tasks.where.not(progress: :completed)
      @milestone = Milestone.new

      flash.now[:alert] = "タスクの作成に失敗しました"
      render "tasks/index", status: :unprocessable_entity
    end
  end

  # PATCH/PUT /tasks/1 or /tasks/1.json
  def update
    respond_to do |format|
      if @task.update(task_params)
        format.html { redirect_to @task, notice: "Task was successfully updated." }
        format.json { render :show, status: :ok, location: @task }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @task.errors, status: :unprocessable_entity }
      end
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
    params.require(:task).permit(:title,
                                 :description,
                                 :progress,
                                 :start_date,
                                 :end_date,
                                 :milestone_id).merge(user_id: current_user.id)
  end

  def ensure_correct_user
    task = Task.find(params[:id])
    user = task.user

    return if user.id == current_user.id

    flash[:alert] = "アクセス権限がありません"
    redirect_to user_path(current_user)
  end
end
