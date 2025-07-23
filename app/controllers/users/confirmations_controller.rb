# frozen_string_literal: true

class Users::ConfirmationsController < Devise::ConfirmationsController
  # def new
  #   super
  # end

  # def create
  #   super
  # end

  def show
    self.resource = resource_class.confirm_by_token(params[:confirmation_token])
    yield resource if block_given?

    if resource.errors.empty?
      set_flash_message!(:notice, :confirmed)

      # 認証完了時は初期データ作成は不要（登録時に既に作成済み）

      sign_in(resource_name, resource)
      respond_with_navigational(resource) { redirect_to after_confirmation_path_for(resource_name, resource) }
    else
      respond_with_navigational(resource.errors, status: :unprocessable_entity) { render :new }
    end
  end

  protected

  def after_resending_confirmation_instructions_path_for(resource_name)
    if signed_in?
      user_path(current_user)
    else
      super
    end
  end

  def after_confirmation_path_for(_resource_name, _resource)
    redirect_path_for_new_user
  end
end
