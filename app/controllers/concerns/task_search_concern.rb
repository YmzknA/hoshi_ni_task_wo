module TaskSearchConcern
  extend ActiveSupport::Concern

  private

  def ransack_result
    @q = @user.tasks.ransack(params[:q])
    @q.sorts = ["start_date asc", "end_date asc"] if @q.sorts.empty?
    @q.result(distinct: true).includes(:milestone)
  end

  def search_tasks_by_title(query)
    # タスクのautocomplete機能で使用
    q = current_user.tasks.ransack("title_cont" => query)
    q.sorts = ["start_date asc", "end_date asc"] if q.sorts.empty?
    q.result(distinct: true).includes(:milestone)
  end

  def search_milestone_tasks(query, milestone)
    # マイルストーン詳細画面からタスクのautocomplete機能を使用する場合
    q = milestone.tasks.ransack("title_cont" => query)
    q.sorts = ["start_date asc", "end_date asc"] if q.sorts.empty?
    q.result(distinct: true).includes(:milestone)
  end

  def search_tasks_by_progress(query, progress)
    tasks = search_tasks_by_title(query)
    if progress == "not_completed"
      # 未完了のタスクを取得
      tasks.not_completed
    else
      tasks.where(progress: progress)
    end
  end
end
