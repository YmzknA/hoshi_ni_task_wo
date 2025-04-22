class GanttChartController < ApplicationController
  before_action :authenticate_user!

  def show
    @milestones = current_user.milestones.includes(:tasks).on_chart.not_completed.start_date_asc

    # 全てのマイルストーンの開始日と終了日から表示する日付範囲を決定
    # min_dateは最小の日付より1日前
    # max_dateは最大の日付より５日後
    min_date, max_date = min_max_date(@milestones)

    # 日付の差分を計算（日数）
    day_diff = (max_date - min_date).to_i + 1

    # 表示する日付の配列
    @date_range = (0...day_diff).map { |i| min_date + i.days }

    # 各マイルストーンの幅と位置を計算
    @chart_total_width = 0

    # @milestonesから、各milestoneのidに紐づけてwidthサイズとleft座標を設定する
    @milestone_widths, @milestone_lefts = milestone_widths_lefts_hash(@milestones)

    # ガントチャート全体の幅を計算（最後のマイルストーンの右端 + 余白）
    @chart_total_width = @milestone_lefts[@milestones.last.id].to_i + @milestone_widths[@milestones.last.id].to_i + 20
  end

  private

  def min_max_date(milestones)
    return if milestones.empty?

    all_dates = @milestones.flat_map { |milestone| [milestone.start_date, milestone.end_date] }
    min_date = all_dates.min - 1.day
    max_date = all_dates.max + 5.day

    [min_date, max_date]
  end

  def milestone_widths_lefts_hash(milestones)
    current_position = 10
    milestone_widths = {}
    milestone_lefts = {}
    milestones.each do |milestone|
      task_count = [milestone.tasks.count, 3].max

      width_size = (task_count * 50)

      # 幅と左位置を保存
      milestone_widths[milestone.id] = width_size.to_s
      milestone_lefts[milestone.id] = current_position.to_s

      # 次の星座の位置を更新
      current_position += width_size + 10
    end

    [milestone_widths, milestone_lefts]
  end
end
