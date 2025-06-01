# frozen_string_literal: true

class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def line
    if user_signed_in?
      # ログイン済みの場合は、LINEアカウントを紐付ける
      link_line_account
    else
      # ログインしていない場合は、LINEアカウントでログインする
      basic_action
    end
  end

  private

  # rubocop:disable Style/RedundantCondition
  # rubocop:disable Layout/LineLength
  def basic_action
    @omniauth = request.env["omniauth.auth"]
    if @omniauth.present?
      @profile = User.find_or_initialize_by(provider: @omniauth["provider"], uid: @omniauth["uid"])
      if @profile.email.blank?
        email = @omniauth["info"]["email"] ? @omniauth["info"]["email"] : "#{@omniauth['uid']}-#{@omniauth['provider']}@example.com"
        @profile = current_user || User.create!(provider: @omniauth["provider"], uid: @omniauth["uid"], email: email, name: @omniauth["info"]["name"], password: Devise.friendly_token[0, 20])
      end
      @profile.set_values(@omniauth)
      @profile.remember_me = true
      sign_in(:user, @profile)
      UserRegistration::MakeTasksMilestones.create_tasks_and_milestones(@profile) if @profile.tasks.empty? && @profile.milestones.empty?
    end

    # ログイン後のflash messageとリダイレクト先を設定
    flash[:notice] = "ログインしました"
    redirect_to user_path(current_user)
  end
  # rubocop:enable Style/RedundantCondition
  # rubocop:enable Layout/LineLength

  # rubocop:disable Lint/UnusedMethodArgument
  def fake_email(uid, provider)
    "#{auth.uid}-#{auth.provider}@example.com"
  end

  def link_line_account
    @omniauth = request.env["omniauth.auth"]

    # omniauthの情報が正しいか確認
    unless @omniauth && @omniauth["provider"].present? && @omniauth["uid"].present?
      flash[:alert] = "LINE連携に失敗しました"
      return redirect_to user_path(current_user)
    end

    # 既に他のユーザーがこのLINEアカウントを紐付けていないか確認
    if User.exists?(provider: @omniauth["provider"], uid: @omniauth["uid"])
      flash[:alert] = "このLINEアカウントは既に登録されています"
    else
      current_user.update!(provider: @omniauth["provider"], uid: @omniauth["uid"])
      flash[:notice] = "LINEアカウントを紐付けました"
    end

    redirect_to user_path(current_user)
  end
end
# rubocop:enable Lint/UnusedMethodArgument
