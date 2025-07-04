# rubocop:disable Metrics/ClassLength
class MilestonesController < ApplicationController
  include GanttChartHelper
  include SearchConcern

  before_action :set_milestone, only: [:show, :edit, :update, :destroy, :complete, :show_complete_page]
  before_action :authenticate_user!, except: [:show]
  before_action :ensure_correct_user, only: [:edit, :update, :destroy]

  def index
    @user = current_user
    user_milestones = ransack_by_title_and_description("milestone")
    @milestone = Milestone.new

    @sharing_milestones = @user.limited_sharing_milestones&.order(created_at: :desc)

    # partitionメソッドを使用して、completed?がtrueのものとfalseのものに分ける
    @completed_milestones, @not_completed_milestones = user_milestones.partition(&:completed?)
    @title = "星座一覧"
  end

  def show
    if other_guest_milestone?(@milestone)
      flash[:alert] = "星座が見つかりませんでした"
      redirect_to tasks_path
      return
    end

    @title = if current_user?(@milestone.user)
               "星座詳細"
             else
               "#{@milestone.user.name}さんの星座詳細"
             end

    if @milestone.is_public || current_user?(@milestone.user)
      prepare_meta_tags(@milestone)
      @chart_presenter = GanttChartPresenter.new([@milestone]) if @milestone.on_chart?

      @milestone_tasks = tasks_ransack_from_milestone(@milestone)
      @from_milestone_show = true
      @task = Task.new
    else
      flash[:alert] = "この星座は非公開です"
      redirect_to milestones_path
    end
  end

  def new
    if current_user.guest?
      flash[:alert] = "ゲストユーザーは星座を作成できません"
      redirect_to tasks_path
      return
    end

    @milestone = Milestone.new
  end

  def edit; end

  def create
    if current_user.guest?
      flash[:alert] = "ゲストユーザーは星座を作成できません"
      redirect_to tasks_path
      return
    end

    @milestone = Milestone.new(milestone_params)

    if @milestone.save
      flash[:notice] = "星座を作成しました"
      redirect_to milestones_path
    else
      # renderで/indexを表示するため、indexアクションと同様の処理
      @user = current_user
      user_milestones = ransack_by_title_and_description("milestone")

      @completed_milestones, @not_completed_milestones = user_milestones.partition(&:completed?)
      @sharing_milestones = @user.limited_sharing_milestones&.order(created_at: :desc)
      @title = "星座一覧"
      @milestones_new_modal_open = true

      flash.now[:alert] = "星座の作成に失敗しました"
      render :index, status: :unprocessable_entity
    end
  end

  def update
    if @milestone.update(milestone_params)
      redirect_to @milestone, notice: "星座を更新しました"
    else
      # renderで/showを表示するため、showアクションと同様の処理
      prepare_for_chart(@milestone)
      @title = "星座詳細"
      @milestones_edit_modal_open = true
      @milestone_tasks = tasks_ransack_from_milestone(@milestone)
      @task = Task.new
      @from_milestone_show = true

      flash.now[:alert] = "星座の更新に失敗しました"
      render "milestones/show", status: :unprocessable_entity
    end
  end

  def destroy
    with_task = params[:with_task] == "true"

    ActiveRecord::Base.transaction do
      if with_task
        tasks = @milestone.tasks
        tasks.each { |task| task&.destroy! }
        flash[:notice] = "星座とそのタスクを削除しました"
      else
        flash[:notice] = "星座を削除しました"
      end

      @milestone.destroy!
    end

    redirect_to milestones_path, status: :see_other
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotDestroyed => e
    flash[:alert] = "削除に失敗しました: #{e.message}"
    redirect_to @milestone
  end

  # ####################
  # CRUD以外のアクション
  # ###############################
  def show_complete_page; end

  def complete
    # 星座をランダムに決定するクラスメソッドに使用する
    num_of_tasks = @milestone.tasks.count
    range_of_stars = Constellation.range_of_stars_from_num_of_tasks(num_of_tasks)

    @milestone.constellation = Constellation.random_constellation_from_num_of_stars(range_of_stars)
    @milestone.progress = "completed"
    @milestone.completed_comment = params[:milestone][:completed_comment]

    if @milestone.save
      @milestone_complete_success = true
      @completed_page_modal_open = true
      flash.now[:notice] = "星座が完成しました"
    else
      @milestone_complete_success = false
      @show_complete_page_modal_open = true
      flash[:alert] = "星座の完成に失敗しました"
    end
  end

  def autocomplete
    progress = params[:progress]

    milestones = autocomplete_by_title("milestone")

    # progressパラメータでフィルタリング
    if progress.present? && progress != "all"
      milestones = case progress
                   when "not_completed"
                     milestones.not_completed
                   when "completed"
                     milestones.completed
                   else
                     milestones.where(progress: progress)
                   end
    end

    # titleの重複を排除
    @milestones = milestones.group_by(&:title).map { |_, milestone_group| milestone_group.first }
  end

  # ##################
  # private methods
  # ############################
  private

  def set_milestone
    @milestone = Milestone.find_by(id: params[:id])
    return if @milestone

    flash[:alert] = "指定された星座が見つかりません"
    redirect_to milestones_path
  end

  def milestone_params
    params.require(:milestone).permit(
      :title,
      :color,
      :description,
      :is_public,
      :is_on_chart,
      :start_date,
      :end_date,
      :completed_comment
    ).merge(user_id: current_user.id)
  end

  def ensure_correct_user
    milestone = Milestone.find(params[:id])
    user = milestone.user

    return if user.id == current_user.id

    flash[:alert] = "アクセス権限がありません"
    redirect_to user_path(current_user)
  end

  def other_guest_milestone?(milestone)
    # ゲストユーザーの星座は非公開
    # 他のユーザーがゲストユーザーの星座を見ようとした場合、制限する
    return false if !milestone.user.guest? || current_user?(milestone.user)

    true
  end

  def prepare_meta_tags(milestone)
    # このimage_urlにMiniMagickで設定したOGPの生成した合成画像を代入する

    title = milestone.title
    if milestone.constellation.present?
      image_name = milestone.constellation.image_name
      image_url = "#{request.base_url}/images/ogp.png?text=#{CGI.escape(title)}&image_name=#{CGI.escape(image_name)}"
    else
      image_url = "#{request.base_url}/images/ogp.png?text=#{CGI.escape(title)}"
    end

    set_meta_tags og: {
                    title: milestone.title,
                    description: milestone.description,
                    url: request.original_url,
                    image: image_url
                  },
                  twitter: {
                    image: image_url
                  }
  end
end
# rubocop:enable Metrics/ClassLength
