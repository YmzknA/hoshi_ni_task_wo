class GanttChartController < ApplicationController
  include GanttChartHelper
  before_action :authenticate_user!

  def show
    if current_user.milestones.empty?
      flash[:alert] = "星座がひとつもありません"
      redirect_to user_path(current_user)
      return
    end

    @milestones = current_user.milestones.includes(:tasks).on_chart.not_completed.start_date_asc

    # 全てのマイルストーンの開始日と終了日から表示する日付範囲を決定
    # 始まりはmilestones最小の日付より1日前
    # 終わりはmilestones最大の日付より５日後
    @date_range = date_range(@milestones)

    # 各マイルストーンの幅と位置を計算
    @chart_total_width = 0

    # @milestonesから、各milestoneのidに紐づけてwidthサイズとleft座標を設定する
    @milestone_widths, @milestone_lefts = milestone_widths_lefts_hash(@milestones)

    # ガントチャート全体の幅を計算（最後のマイルストーンの右端 + 余白）
    @chart_total_width = @milestone_lefts[@milestones.last.id].to_i + @milestone_widths[@milestones.last.id].to_i + 20
  end

  def milestone_show
    @milestone = current_user.milestones.find(params[:id])
    @milestone_tasks = @milestone.tasks
  end
end
