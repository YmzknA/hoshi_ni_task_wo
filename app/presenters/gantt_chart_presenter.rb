class GanttChartPresenter
  include GanttChartHelper

  attr_reader :milestones

  def initialize(milestones)
    @milestones = milestones
  end

  def chart_data
    {
      date_range: date_range(@milestones), # チャートの日付範囲
      milestone_widths: milestone_widths, # 星座ごとの幅
      milestone_lefts: milestone_lefts, # 星座ごとの左位置
      chart_total_width: chart_total_width, # チャート全体の幅
      milestones: @milestones # chart_presenter.milestonesでも参照できるが、chart_dataでまとめて取得することで統一した記述にしている
    }
  end

  private

  def milestone_widths
    milestone_widths_lefts_hash(@milestones)[0] # メソッドの戻り値は[widths, lefts]の配列
  end

  def milestone_lefts
    milestone_widths_lefts_hash(@milestones)[1] # メソッドの戻り値は[widths, lefts]の配列
  end

  def chart_total_width
    last_milestone_left = milestone_lefts[@milestones.last.id]
    last_milestone_width = milestone_widths[@milestones.last.id]
    last_milestone_left + last_milestone_width + CHART_END_MARGIN
  end
end
