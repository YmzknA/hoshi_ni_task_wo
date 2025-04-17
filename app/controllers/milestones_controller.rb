class MilestonesController < ApplicationController
  before_action :set_milestone, only: [:show, :edit, :update, :destroy]
  before_action :ensure_correct_user, only: [:create, :edit, :update, :destroy]

  # GET /milestones or /milestones.json
  def index
    @user = current_user
    @completed_milestones = @user.milestones.where(progress: "completed")
    @not_completed_milestones = @user.milestones.where.not(progress: "completed")
    @title = "星座一覧"
  end

  # GET /milestones/1 or /milestones/1.json
  def show
    @title = if current_user?(@milestone.user)
               "星座詳細"
             else
               "#{@milestone.user.name}さんの星座詳細"
             end

    if @milestone.is_public || @milestone.user.id == current_user.id
      @milestone_tasks = @milestone.tasks
    else
      flash[:alert] = "この星座は非公開です"
      redirect_to user_path(current_user)
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
      redirect_to user_check_path
    else
      @milestone_new_modal_open = true
      @task = Task.new
      @tasks = Task.all
      @milestones = Milestone.all
      flash.now[:alert] = "星座の作成に失敗しました"
      render "static_pages/user_check", status: :unprocessable_entity
    end
  end

  # PATCH/PUT /milestones/1 or /milestones/1.json
  def update
    respond_to do |format|
      if @milestone.update(milestone_params)
        format.html { redirect_to @milestone, notice: "Milestone was successfully updated." }
        format.json { render :show, status: :ok, location: @milestone }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @milestone.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /milestones/1 or /milestones/1.json
  def destroy
    @milestone.destroy!

    respond_to do |format|
      format.html { redirect_to milestones_path, status: :see_other, notice: "Milestone was successfully destroyed." }
      format.json { head :no_content }
    end
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
