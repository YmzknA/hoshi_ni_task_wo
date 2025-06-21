class TaskChartPresenter
  include GanttChartHelper

  def initialize(task, tasks)
    @task = task
    @tasks = tasks
  end

  def task_data
    {
      height: task_height,
      top: task_top,
      left: task_left,
      title_height: task_title_height,
      margin_top: TASK_MARGIN_TOP,
      color: @task.milestone.color,
      task_index: task_index,
      task_count: task_count
    }
  end

  private

  def task_height
    if @task.start_date && @task.end_date
      (task_end_index - task_start_index + 1) * DATE_ROW_HEIGHT
    else
      DATE_ROW_HEIGHT
    end
  end

  def task_top
    if @task.start_date && @task.end_date
      task_start_index * DATE_ROW_HEIGHT
    elsif @task.start_date && !@task.end_date
      task_start_index * DATE_ROW_HEIGHT
    elsif !@task.start_date && @task.end_date
      task_end_index * DATE_ROW_HEIGHT
    else
      0 # 両方無い場合はここに来ることはないはず
    end
  end

  def milestone_width_size
    task_count * WIDTH_PER_TASK
  end

  def task_left
    section_ratio = 1.000 / (@tasks.count + 1)
    ((milestone_width_size * section_ratio * (task_index + 1)) - TASK_RIGHT_MARGIN_FROM_BORDER).to_i
  end

  def task_title_height
    ([@task.title.length, TASK_TITLE_MAX_LENGTH].min + 1) * HEIGHT_PER_CHARS
  end

  def task_index
    @tasks.index(@task)
  end

  def task_count
    [@tasks.count, TASK_MIN_COUNT].max
  end

  def task_start_index
    (@task.start_date - @task.milestone.start_date).to_i
  end

  def task_end_index
    (@task.end_date - @task.milestone.start_date).to_i
  end
end
