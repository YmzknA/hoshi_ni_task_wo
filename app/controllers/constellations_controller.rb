class ConstellationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_constellation, only: [:show]

  def index
    @title = "88星座図鑑"
    @user = current_user
    @constellations = Constellation.all.order(:number_of_stars)
    @user_constellation_ids = current_user.milestones.completed.where.not(constellation: nil).pluck(:constellation_id)
  end

  def show
    @title = "#{@constellation.name}に紐づく星座"
    @user = current_user
    @milestones = current_user.milestones.where(constellation: @constellation).order(start_date: :desc)
  end

  private

  def set_constellation
    @constellation = Constellation.find_by(id: params[:id])
    return if @constellation

    flash[:alert] = "星座が見つかりませんでした"
    redirect_to constellations_path
  end
end
