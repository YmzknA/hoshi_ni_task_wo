module ChartUpdateConcern
  extend ActiveSupport::Concern

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
    referer.include?("/gantt_chart")
  end

  def setup_chart_update_data
    return unless chart_needs_update?

    @chart_milestones = current_user.milestones.includes(:tasks).on_chart.not_completed.start_date_asc
    return if @chart_milestones.empty?

    @chart_presenter = GanttChartPresenter.new(@chart_milestones, current_user)
    @chart_data = @chart_presenter.chart_data
  end

  def chart_needs_update?
    @task_milestone&.on_chart? || @previous_milestone&.on_chart?
  end
end
