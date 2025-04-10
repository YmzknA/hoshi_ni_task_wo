class StaticPagesController < ApplicationController
  def home
  end

  def user_check
    if user_signed_in?
      @user = current_user
    else
      @user = nil
    end
  end
end
