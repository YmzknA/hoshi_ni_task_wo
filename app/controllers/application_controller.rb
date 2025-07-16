class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  def current_user?(user)
    user && user == current_user
  end

  protected

  def redirect_path_for_new_user
    how_to_use_path
  end
end
