class MilestoneChartPresenter
  include ::GanttChartHelper

  def initialize(milestone, date_range, milestone_widths, milestone_lefts, current_user)
    @milestone = milestone
    @date_range = date_range
    @milestone_widths = milestone_widths
    @milestone_lefts = milestone_lefts
    @current_user = current_user
  end

  def milestone_data
    {
      start_index: start_index,
      end_index: end_index,
      height: milestone_height,
      top: milestone_top,
      width: milestone_width,
      left: milestone_left,
      color: @milestone.color,
      truncate_num: milestone_title_truncate_num,
      tasks: tasks
    }
  end

  private

  def tasks
    # 関連を再読み込みして最新のタスクを取得
    @milestone.reload
    base_tasks = @milestone.tasks.valid_dates_nil

    if @current_user&.completed_tasks_hidden?
      tasks = base_tasks.not_completed.start_date_asc
    else
      not_completed_tasks = base_tasks.not_completed.start_date_asc
      completed_tasks = base_tasks.completed.start_date_asc

      tasks = not_completed_tasks + completed_tasks
    end

    tasks
  end

  def start_index
    @date_range.index { |d| d.to_date == @milestone.start_date.to_date }
  end

  def end_index
    @date_range.index { |d| d.to_date == @milestone.end_date.to_date }
  end

  def milestone_height
    (end_index - start_index + 1) * DATE_ROW_HEIGHT
  end

  def milestone_top
    start_index * DATE_ROW_HEIGHT
  end

  def milestone_width
    @milestone_widths[@milestone.id]
  end

  def milestone_left
    @milestone_lefts[@milestone.id]
  end

  # タスク数に応じて幅が変わるため、それに応じてタイトルの文字数を決定
  def milestone_title_truncate_num
    [@milestone.tasks.count * CHARS_PER_TASK, MILESTONE_TITLE_MIN_LENGTH].max
  end
end
