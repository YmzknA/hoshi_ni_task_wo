class UsersController < ApplicationController
  def show
    @user = User.find_by(id: params[:id])

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

  private

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
