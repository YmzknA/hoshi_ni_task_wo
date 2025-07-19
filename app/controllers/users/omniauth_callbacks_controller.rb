# frozen_string_literal: true

class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  include UserInitializationConcern
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

  def basic_action
    @omniauth = request.env["omniauth.auth"]
    is_new_user = false # 初期値を設定
    if @omniauth.present?
      @profile = User.find_or_initialize_by(provider: @omniauth["provider"], uid: @omniauth["uid"])
      if @profile.email.blank?
        email = fake_email(@omniauth["provider"])
        @profile = current_user || User.create!(
          provider: @omniauth["provider"],
          uid: @omniauth["uid"],
          email: email,
          name: @omniauth["info"]["name"],
          password: Devise.friendly_token[0, 20],
          confirmed_at: Time.current # LINE認証ユーザーは自動的に認証済み
        )
      end
      @profile.remember_me = true
      sign_in(:user, @profile)

      initialize_new_user(@profile)
    end

    # ログイン後のflash messageとリダイレクト先を設定
    flash[:notice] = "ログインしました"
    redirect_to is_new_user ? redirect_path_for_new_user : user_path(current_user)
  end

  def fake_email(provider)
    random_id = Nanoid.generate(size: NanoidGenerator::ID_LENGTH, alphabet: NanoidGenerator::ID_ALPHABET)
    "#{random_id}-#{provider}@example.com"
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
      current_user.update!(
        provider: @omniauth["provider"],
        uid: @omniauth["uid"],
        confirmed_at: Time.current # LINE連携時も認証済みにする
      )
      flash[:notice] = "LINEアカウントを紐付けました"
    end

    redirect_to user_path(current_user)
  end
end
