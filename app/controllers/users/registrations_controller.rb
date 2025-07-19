# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  include UserInitializationConcern
  
  before_action :configure_sign_up_params, only: [:create]
  before_action :configure_account_update_params, only: [:update]
  before_action :valid_restricted_user, only: [:update, :edit]

  # GET /resource/sign_up
  # def new
  #   super
  # end

  # POST /resource
  def create
    build_resource(sign_up_params)

    resource.save
    yield resource if block_given?
    if resource.persisted?
      # メール認証必須でもログインさせる
      set_flash_message! :notice, :signed_up
      sign_up(resource_name, resource)

      # sign_up後に紐づくtasksを作成（未認証でもサンプルタスクを作成）
      initialize_new_user(resource)

      respond_with resource, location: after_sign_up_path_for(resource)
    else
      clean_up_passwords resource
      set_minimum_password_length
      respond_with resource
    end
  end

  # GET /resource/edit
  # def edit
  #   super
  # end

  # PUT /resource
  def update
    self.resource = resource_class.to_adapter.get!(send(:"current_#{resource_name}").to_key)
    prev_unconfirmed_email = resource.unconfirmed_email if resource.respond_to?(:unconfirmed_email)

    resource_updated = update_resource(resource, account_update_params)
    yield resource if block_given?
    if resource_updated
      set_flash_message_for_update(resource, prev_unconfirmed_email)
      bypass_sign_in resource, scope: resource_name if sign_in_after_change_password?

      respond_with resource, location: after_update_path_for(resource)
    else
      clean_up_passwords resource
      set_minimum_password_length

      @user = resource
      user_milestones = current_user.milestones
      @title = "ユーザーページ"
      @modal_open = true
      @not_completed_milestones = user_milestones.where.not(progress: "completed")
      @completed_milestones = user_milestones.where(progress: "completed")
      render "users/show", status: :unprocessable_entity
    end
  end

  # DELETE /resource
  # def destroy
  #   super
  # end
  #
  def guest_sign_in
    user = nil

    ActiveRecord::Base.transaction do
      retries = 0
      begin
        user = User.guest
        initialize_new_user(user)
      rescue ActiveRecord::RecordNotUnique => e
        retries += 1
        raise e unless retries < 3

        sleep(0.1 * retries) # 指数バックオフ: 0.1秒, 0.2秒, 0.3秒
        retry
      end
    end

    sign_in user
    redirect_to redirect_path_for_new_user, notice: "ゲストユーザーでログインしました。"
  rescue StandardError => e
    Rails.logger.error "Guest user creation failed: #{e.message}"
    redirect_to root_path, alert: "ゲストログインに失敗しました。もう一度お試しください。"
  end

  # GET /resource/cancel
  # Forces the session data which is usually expired after sign
  # in to be expired now. This is useful if the user wants to
  # cancel oauth signing in/up in the middle of the process,
  # removing all OAuth session data.
  # def cancel
  #   super
  # end

  protected

  # If you have extra params to permit, append them to the sanitizer.
  def configure_sign_up_params
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name])
  end

  # If you have extra params to permit, append them to the sanitizer.
  def configure_account_update_params
    devise_parameter_sanitizer.permit(:account_update, keys: [:name, :bio])
  end

  # The path used after sign up.
  def after_sign_up_path_for(_resource)
    redirect_path_for_new_user
  end

  def after_update_path_for(resource)
    user_path(resource)
  end

  def valid_restricted_user
    return unless current_user.restricted_user?

    flash[:alert] = if current_user.guest?
                      "ゲストユーザーはプロフィールの編集ができません"
                    else
                      "メール認証を完了すると、プロフィールを編集できるようになります"
                    end
    redirect_to user_path(current_user)
  end

  def update_resource(resource, params)
    resource.update_without_password(params)
  end

  # The path used after sign up for inactive accounts.
  # def after_inactive_sign_up_path_for(resource)
  #   super(resource)
  # end
end
