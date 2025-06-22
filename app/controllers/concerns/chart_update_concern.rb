module ChartUpdateConcern
  extend ActiveSupport::Concern

  GANTT_CHART_PATH = "/gantt_chart".freeze

  private

  def sort_tasks_by_complete_and_start_date(tasks)
    # 完了したタスクを後ろにして、それぞれ開始日でソート
    not_completed_tasks = tasks.not_completed.start_date_asc
    completed_tasks = tasks.completed.start_date_asc
    not_completed_tasks + completed_tasks
  end

  def set_chart_tasks
    return unless @task_milestone.on_chart?

    tasks = fetch_chart_tasks
    @chart_tasks = sort_tasks_by_complete_and_start_date(tasks).to_a

    # いま処理しているタスクがまだdbに存在していればチャートに表示するために追加
    current_task = @task_milestone.tasks.find_by(id: @task.id)
    @chart_tasks << current_task if current_task && @chart_tasks.exclude?(current_task)
  end

  def fetch_chart_tasks
    # アクセス元のページを判定してタスクを取得
    # チャート画面からのアクセスの場合：完了タスクを非表示にする設定を確認する
    # 星座詳細画面からのアクセスの場合：常にすべてのタスクを表示
    return @task_milestone.tasks.valid_dates_nil unless from_chart_page?

    if current_user.completed_tasks_hidden?
      @task_milestone.tasks.not_completed.valid_dates_nil
    else
      @task_milestone.tasks.valid_dates_nil
    end
  end

  def from_chart_page?
    # URLからアクセス元のページを判定
    referer = request.referer
    return false if referer.blank?

    # チャート画面のURLパターンをチェック
    referer.include?(GANTT_CHART_PATH)
  end

  def setup_chart_update_data
    return unless chart_needs_update?

    if from_chart_page?
      setup_chart_page_data
    else
      setup_milestone_detail_page_data
    end
  end

  def setup_chart_page_data
    @chart_milestones = current_user.milestones.includes(:tasks).on_chart.not_completed.start_date_asc
    return if @chart_milestones.empty?

    @chart_presenter = GanttChartPresenter.new(@chart_milestones, current_user)
    @chart_data = @chart_presenter.chart_data
  end

  def setup_milestone_detail_page_data
    affected_milestones = set_affected_milestones
    @single_milestone_updates = create_single_milestone_data(affected_milestones)
  end

  def set_affected_milestones
    affected_milestones = []
    affected_milestones << @task_milestone if @task_milestone&.on_chart?

    if @previous_milestone && @previous_milestone != @task_milestone && @previous_milestone.on_chart?
      affected_milestones << @previous_milestone
    end

    affected_milestones
  end

  def create_single_milestone_data(milestones)
    milestones.map do |milestone|
      single_milestone_data = [milestone]
      chart_presenter = GanttChartPresenter.new(single_milestone_data, current_user)
      {
        milestone: milestone,
        chart_presenter: chart_presenter,
        chart_data: chart_presenter.chart_data
      }
    end
  end

  def chart_needs_update?
    @task_milestone&.on_chart? || @previous_milestone&.on_chart?
  end
end
