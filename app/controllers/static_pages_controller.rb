class StaticPagesController < ApplicationController
  def home
  end

  def privacy_policy
  end

  def terms_of_service
  end

  def user_check
    @user = current_user if user_signed_in?
    @milestone = Milestone.new
  end
end
