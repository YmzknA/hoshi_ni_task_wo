module GanttChartHelper
  def milestone_widths_lefts_hash(milestones)
    current_position = 15
    milestone_widths = {}
    milestone_lefts = {}

    # マイルストーンのタスク数を取得
    if milestones.first.instance_of?(Milestone)
      task_counts = Task.where(milestone_id: milestones.map(&:id)).group(:milestone_id).count
    elsif milestones.first.instance_of?(LimitedSharingMilestone)
      # 渡されたmilestonesがLimitedSharingMilestoneの場合
      # rubocop:disable Layout/LineLength
      task_counts = LimitedSharingTask.where(limited_sharing_milestone_id: milestones.map(&:id)).group(:limited_sharing_milestone_id).count
      # rubocop:enable Layout/LineLength
    end

    milestones.each do |milestone|
      task_counts[milestone.id] = 0 if task_counts[milestone.id].nil?

      task_count = [task_counts[milestone.id], 3].max

      width_size = width_size(task_count, milestone)

      # 幅と左位置を保存
      milestone_widths[milestone.id] = width_size.to_s
      milestone_lefts[milestone.id] = current_position.to_s

      # 次の星座の位置を更新
      current_position += width_size + 15
    end

    [milestone_widths, milestone_lefts]
  end

  def min_max_date(milestones)
    return if milestones.empty?

    all_dates = milestones.flat_map { |milestone| [milestone.start_date, milestone.end_date] }
    min_date = all_dates.min - 1.day
    max_date = all_dates.max + 5.day

    [min_date, max_date]
  end

  def date_range(milestones)
    # 全てのマイルストーンの開始日と終了日から表示する日付範囲を決定
    # min_dateは最小の日付より1日前
    # max_dateは最大の日付より５日後
    min_date, max_date = min_max_date(milestones)

    # 日付の差分を計算（日数）
    day_diff = (max_date - min_date).to_i + 1

    # 表示する日付の配列
    (0...day_diff).map { |i| min_date + i.days }
  end

  def sort_completed(sources)
    sources.sort_by do |source|
      if source.completed?
        1
      else
        0
      end
    end
  end

  def width_size(task_count, milestone)
    # タスク数に応じて幅を設定
    if milestone.open?
      80 * task_count
    else
      45
    end
  end
end
