class MilestonesController < ApplicationController
  before_action :set_milestone, only: [:show, :edit, :update, :destroy]

  # GET /milestones or /milestones.json
  def index
    @milestones = Milestone.all
  end

  # GET /milestones/1 or /milestones/1.json
  def show
    if @milestone.is_public || @milestone.user.id == current_user.id
      @title = "星座詳細"
      @milestone_tasks = @milestone.tasks
    else
      flash[:alert] = "この星座は非公開です"
      redirect_to user_check_path
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
      :description,
      :is_public,
      :is_on_chart,
      :start_date,
      :end_date
    ).merge(user_id: current_user.id)
  end
end
