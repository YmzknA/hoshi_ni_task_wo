class StaticPagesController < ApplicationController
  def home
  end

  def user_check
    @user = current_user if user_signed_in?
  end
end
