module AuthorizationConcern
  extend ActiveSupport::Concern

  private

  def ensure_resource_owner(resource)
    return if resource.user_id == current_user.id

    flash[:alert] = t("restrictions.access_denied")
    redirect_to current_user ? user_path(current_user) : root_path
  end

  def restrict_user_action(action)
    return unless current_user.restricted_user?

    flash[:alert] = if current_user.guest?
                      t("restrictions.guest_user.#{action}")
                    else
                      t("restrictions.email_unconfirmed.#{action}")
                    end
    redirect_to tasks_path
    true
  end
end
