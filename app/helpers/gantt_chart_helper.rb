module GanttChartHelper
  # 日付行の高さ（px）
  DATE_ROW_HEIGHT = 40

  # 星座のタイトルの表示文字数を決める際に使用する
  CHARS_PER_TASK = 2
  MILESTONE_TITLE_MIN_LENGTH = 10

  # タスクチャートの設定
  TASK_MARGIN_TOP = 8
  TASK_TITLE_MAX_LENGTH = 15
  HEIGHT_PER_CHARS = 15
  TASK_MIN_COUNT = 3
  WIDTH_PER_TASK = 80
  # ↓この値で、星座の右端ボーダーにタスクが重ならないように調整
  TASK_RIGHT_MARGIN_FROM_BORDER = 9.5 # ボーダーの幅の半分(1.5px) + タスクの幅(size-4)の半分(8px)

  # 星座幅設定
  MILESTONE_CLOSED_WIDTH = 45
  MILESTONE_SPACING = 15
  MILESTONE_INITIAL_POSITION = 15

  # チャート最後に足す隙間
  CHART_END_MARGIN = 20

  # チャート全体の日付範囲設定
  DISPLAY_START_MARGIN_DAYS = 1  # 含まれる星座の最速の開始日より何日前から表示
  DISPLAY_END_MARGIN_DAYS = 5    # 含まれる星座の最遅の終了日より何日後まで表示

  # ヘッダー高さ
  MILESTONE_HEADER_HEIGHT = 35
  MILESTONE_HEADER_SHIFT_UP = 30 # チャート部分ヘッダーを上にずらすための値

  # 星座のマージン設定
  MILESTONE_HEADER_WIDTH_MARGIN = 20
  MILESTONE_HEADER_LEFT_MARGIN = 10

  def milestone_widths_lefts_hash(milestones, user = nil)
    current_position = MILESTONE_INITIAL_POSITION
    milestone_widths = {}
    milestone_lefts = {}

    # 星座のタスク数を取得
    if milestones.first.instance_of?(Milestone)
      task_counts = if user&.completed_tasks_hidden?
                      Task.where(milestone_id: milestones.map(&:id)).not_completed.group(:milestone_id).count
                    else
                      Task.where(milestone_id: milestones.map(&:id)).group(:milestone_id).count
                    end
    elsif milestones.first.instance_of?(LimitedSharingMilestone)
      # 渡されたmilestonesがLimitedSharingMilestoneの場合
      # rubocop:disable Layout/LineLength
      task_counts = LimitedSharingTask.where(limited_sharing_milestone_id: milestones.map(&:id)).group(:limited_sharing_milestone_id).count
      # rubocop:enable Layout/LineLength
    end

    milestones.each do |milestone|
      task_counts[milestone.id] = 0 if task_counts[milestone.id].nil?

      task_count = [task_counts[milestone.id], TASK_MIN_COUNT].max

      width_size = width_size(task_count, milestone)

      # 幅と左位置を保存
      milestone_widths[milestone.id] = width_size
      milestone_lefts[milestone.id] = current_position

      # 次の星座の位置を更新
      current_position += width_size + MILESTONE_SPACING
    end

    [milestone_widths, milestone_lefts]
  end

  def min_max_date(milestones)
    return if milestones.empty?

    all_dates = milestones.flat_map { |milestone| [milestone.start_date, milestone.end_date] }
    min_date = all_dates.min - DISPLAY_START_MARGIN_DAYS.days
    max_date = all_dates.max + DISPLAY_END_MARGIN_DAYS.days

    [min_date, max_date]
  end

  def date_range(milestones)
    # 全ての星座の開始日と終了日から表示する日付範囲を決定
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
      WIDTH_PER_TASK * task_count
    else
      MILESTONE_CLOSED_WIDTH
    end
  end

  def milestone_title_truncate_num(milestone)
    [milestone.tasks.count * CHARS_PER_TASK, MILESTONE_TITLE_MIN_LENGTH].max
  end

  def date_class(date)
    if date == Time.zone.today
      "today"
    elsif date.wday.zero? || date.wday == 6
      "weekend"
    else
      "weekday"
    end
  end

  def date_line_color(date)
    case date_class(date)
    when "today"
      "bg-accent/20"
    when "weekend"
      "bg-error/20"
    else
      ""
    end
  end

  def date_header_color(date)
    case date_class(date)
    when "today"
      "bg-accent/70"
    when "weekend"
      "bg-error/70"
    else
      ""
    end
  end
end
