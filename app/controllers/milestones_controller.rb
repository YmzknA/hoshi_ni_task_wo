class MilestonesController < ApplicationController
  before_action :set_milestone, only: [:show, :edit, :update, :destroy]
  before_action :authenticate_user!, except: [:show]
  before_action :ensure_correct_user, only: [:edit, :update, :destroy]

  # GET /milestones or /milestones.json
  def index
    @user = current_user
    user_milestones = @user.milestones
    @milestone = Milestone.new
    @completed_milestones = user_milestones.where(progress: "completed")&.order(created_at: :desc)
    @not_completed_milestones = user_milestones.where&.not(progress: "completed")&.order(created_at: :desc)
    @title = "星座一覧"
  end

  # GET /milestones/1 or /milestones/1.json
  def show
    @title = if current_user?(@milestone.user)
               "星座詳細"
             else
               "#{@milestone.user.name}さんの星座詳細"
             end

    if @milestone.is_public || current_user?(@milestone.user)
      @milestone_tasks = @milestone.tasks
      @task = Task.new
    else
      flash[:alert] = "この星座は非公開です"
      redirect_to milestones_path
    end
  end

  # GET /milestones/new
  def new
    @milestone = Milestone.new
  end

  # GET /milestones/1/edit
  def edit; end

  # POST /milestones or /milestones.json
  def create
    @milestone = Milestone.new(milestone_params)

    if @milestone.save
      flash[:notice] = "星座を作成しました"
      redirect_to milestones_path
    else
      @user = current_user
      user_milestones = @user.milestones
      @completed_milestones = user_milestones.where(progress: "completed")&.order(created_at: :desc)
      @not_completed_milestones = user_milestones.where&.not(progress: "completed")&.order(created_at: :desc)
      @title = "星座一覧"
      @milestones_new_modal_open = true

      flash.now[:alert] = "星座の作成に失敗しました"
      render :index, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /milestones/1 or /milestones/1.json
  def update
    if @milestone.update(milestone_params)
      redirect_to @milestone, notice: "星座を更新しました"
    else
      @title = "星座詳細"
      @milestones_edit_modal_open = true
      @milestone_tasks = @milestone.tasks
      flash.now[:alert] = "星座の更新に失敗しました"
      render "milestones/show", status: :unprocessable_entity
    end
  end

  # DELETE /milestones/1
  def destroy
    with_task = params[:with_task] == "true"

    if with_task
      tasks = @milestone.tasks
      tasks.each { |task| task&.destroy! }
      flash[:notice] = "星座とそのタスクを削除しました"
    else
      flash[:notice] = "星座を削除しました"
    end

    @milestone.destroy!

    redirect_to milestones_path, status: :see_other
  end

  private

  def set_milestone
    @milestone = Milestone.find(params[:id])
  end

  def milestone_params
    params.require(:milestone).permit(
      :title,
      :color,
      :description,
      :is_public,
      :is_on_chart,
      :start_date,
      :end_date
    ).merge(user_id: current_user.id)
  end

  def ensure_correct_user
    milestone = Milestone.find(params[:id])
    user = milestone.user

    return if user.id == current_user.id

    flash[:alert] = "アクセス権限がありません"
    redirect_to user_path(current_user)
  end
end
