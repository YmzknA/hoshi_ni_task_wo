class UsersController < ApplicationController
  before_action :authenticate_user!, except: [:show]
  before_action :set_user, only: [:show, :toggle_notifications]
  before_action :validate_another_user, only: [:toggle_notifications]

  def show
    # @userがnilであるか、またはゲストユーザかつ現在のユーザと異なる場合はリダイレクト
    # ゲストユーザーはノイズになるのを避けるために、他者に詳細画面を表示しない
    if @user.nil? || (@user.guest? && !current_user?(@user))
      redirect_to root_path, alert: "ユーザが見つかりません"
    else
      @title = "ユーザーページ"
      prepare_meta_tags(@user)

      if current_user?(@user)
        @not_completed_milestones = not_completed_milestones(public: false)
        @completed_milestones = completed_milestones(public: false)
      else
        @not_completed_milestones = not_completed_milestones(public: true)
        @completed_milestones = completed_milestones(public: true)
      end
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

  def not_completed_milestones(public: false)
    if public
      @user.milestones
           .where(is_public: true)
           .where.not(progress: "completed")
           .index_order
    else
      @user.milestones
           .where.not(progress: "completed")
           .index_order
    end
  end

  def completed_milestones(public: false)
    if public
      @user.milestones
           .where(is_public: true)
           .where(progress: "completed")
           .index_order
    else
      @user.milestones
           .where(progress: "completed")
           .index_order
    end
  end
end
