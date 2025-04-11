# frozen_string_literal: true

class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def line
    basic_action
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
      sign_in(:user, @profile)
    end
    # ログイン後のflash messageとリダイレクト先を設定
    flash[:notice] = "ログインしました"
    redirect_to user_check_path
  end
  # rubocop:enable Style/RedundantCondition
  # rubocop:enable Layout/LineLength

  # rubocop:disable Lint/UnusedMethodArgument
  def fake_email(uid, provider)
    "#{auth.uid}-#{auth.provider}@example.com"
  end
end
# rubocop:enable Lint/UnusedMethodArgument
