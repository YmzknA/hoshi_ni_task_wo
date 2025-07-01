class UsersController < ApplicationController
  before_action :authenticate_user!, except: [:show]
  before_action :set_user, only: [:show, :toggle_notifications, :toggle_hide_completed_tasks, :update_notification_time]
  before_action :validate_another_user, only: [:toggle_notifications, :toggle_hide_completed_tasks, :update_notification_time]

  def show
    # @userがnilであるか、またはゲストユーザかつ現在のユーザと異なる場合はリダイレクト
    # ゲストユーザーはノイズになるのを避けるために、他者に詳細画面を表示しない
    if @user.nil? || (@user.guest? && !current_user?(@user))
      redirect_to root_path, alert: "ユーザが見つかりません"
    else
      @title = "ユーザーページ"
      prepare_meta_tags(@user)

      # 自分の場合は全て表示、他人の場合はis_publicがtrueのもののみ
      is_show_all = current_user?(@user)

      @not_completed_milestones = milestones_by_completed_and_show_all(completed: false, show_all: is_show_all)
      @completed_milestones = milestones_by_completed_and_show_all(completed: true, show_all: is_show_all)
    end
  end

  def toggle_notifications
    if @user.nil?
      redirect_to root_path, alert: "ユーザが見つかりません"
    else
      @user.is_notifications_enabled = !@user.is_notifications_enabled

      if @user.save
        flash.now[:notice] = if @user.is_notifications_enabled
                               "通知を受け取るように設定しました"
                             else
                               "通知を受け取らないように設定しました"
                             end
      else
        flash.now[:alert] = "通知の切り替えに失敗しました"
      end
    end
  end

  def toggle_hide_completed_tasks
    if @user.nil?
      redirect_to root_path, alert: "ユーザが見つかりません"
    else
      @user.is_hide_completed_tasks = !@user.is_hide_completed_tasks
      if @user.save
        flash.now[:notice] = if @user.is_hide_completed_tasks
                               "完了したタスクを非表示にしました"
                             else
                               "完了したタスクを表示するように設定しました"
                             end
      else
        flash.now[:alert] = "完了したタスクの表示設定の切り替えに失敗しました"
      end

      # turbo_streamで更新する
    end
  end

  def update_notification_time
    if @user.nil?
      redirect_to root_path, alert: "ユーザが見つかりません"
    else
      if @user.update(notification_time_params)
        flash.now[:notice] = "通知時間を#{@user.notification_time}時に設定しました"
      else
        flash.now[:alert] = "通知時間の更新に失敗しました"
      end
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def validate_another_user
    return if current_user?(@user)

    flash[:alert] = "他のユーザーの設定は変更できません"
    redirect_to root_path
  end

  def prepare_meta_tags(user)
    set_meta_tags og: {
      title: "#{user.name}さんのユーザーページ",
      description: "#{user.name}さんのユーザーページです。",
      url: user_url(user)
    }
  end

  def milestones_by_completed_and_show_all(completed: false, show_all: false)
    milestones = @user.milestones.includes(:tasks)

    milestones = completed ? milestones.where(progress: "completed") : milestones.where.not(progress: "completed")

    if show_all
      # 渡し忘れた際などミスがあった場合のために、
      # 明示的にshow_all:trueを指定しないとis_public:trueのものだけを取得する
    else
      milestones = milestones.where(is_public: true)
    end

    milestones.index_order
  end

  def notification_time_params
    params.require(:user).permit(:notification_time)
  end
end
