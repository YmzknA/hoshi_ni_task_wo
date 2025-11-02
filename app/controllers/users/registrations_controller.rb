# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  before_action :configure_sign_up_params, only: [:create]
  before_action :configure_account_update_params, only: [:update]
  before_action :valid_guest_user, only: [:update, :edit]

  # def new
  #   super
  # end

  def create
    build_resource(sign_up_params)

    resource.save
    yield resource if block_given?
    if resource.persisted?
      if resource.active_for_authentication?
        set_flash_message! :notice, :signed_up
        sign_up(resource_name, resource)

        # sign_up後に紐づくtasksを作成
        user = resource
        is_new_user = user.new_user?
        UserRegistration::MakeTasksMilestones.create_tasks_and_milestones(user) if is_new_user

        respond_with resource, location: after_sign_up_path_for(resource)
      else
        set_flash_message! :notice, :"signed_up_but_#{resource.inactive_message}"
        expire_data_after_sign_in!
        respond_with resource, location: after_inactive_sign_up_path_for(resource)
      end
    else
      clean_up_passwords resource
      set_minimum_password_length
      respond_with resource
    end
  end

  # def edit
  #   super
  # end

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
      assign_user_show_variables(resource, open_edit_modal: true)
      render "users/show", status: :unprocessable_entity
    end
  end

  def destroy
    self.resource = resource_class.to_adapter.get!(send(:"current_#{resource_name}").to_key)
    unless delete_confirmation_matches?(resource)
      flash.now[:alert] = "ユーザーネームが一致しません。"
      assign_user_show_variables(resource,
                                 open_delete_modal: true,
                                 delete_confirmation: params.dig(:user, :delete_confirmation))
      render "users/show", status: :unprocessable_entity
      return
    end

    super
  end

  def guest_sign_in
    user = nil

    ActiveRecord::Base.transaction do
      retries = 0
      begin
        user = User.guest
        UserRegistration::MakeTasksMilestones.create_tasks_and_milestones(user) if user.new_user?
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

  def valid_guest_user
    return unless current_user.guest?

    flash[:alert] = "ゲストユーザーはプロフィールの編集ができません"
    redirect_to user_path(current_user)
  end

  def update_resource(resource, params)
    resource.update_without_password(params)
  end

  def assign_user_show_variables(resource, open_edit_modal: false, open_delete_modal: false, delete_confirmation: nil)
    @user = resource
    user_milestones = resource.milestones.includes(:tasks, :constellation)
    @title = "ユーザーページ"

    # 編集失敗時に編集モーダルを開くかどうかの変数
    @modal_open = open_edit_modal

    # delete失敗時に削除モーダルを開くかどうかの変数
    @delete_confirm_modal_open = open_delete_modal
    # 失敗時にフォームの値を保持するために使用
    @delete_confirmation_value = delete_confirmation

    @not_completed_milestones = user_milestones.where.not(progress: "completed")
    @completed_milestones = user_milestones.where(progress: "completed")
  end

  def delete_confirmation_matches?(resource)
    params.dig(:user, :delete_confirmation) == resource.name
  end

  # The path used after sign up for inactive accounts.
  # def after_inactive_sign_up_path_for(resource)
  #   super(resource)
  # end
end
