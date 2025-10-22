module SearchConcern
  extend ActiveSupport::Concern
  include KanaNormalizer

  private

  def ransack_by_title_with_progress(progress)
    kana_query = normalize_kana(params[:q])
    reverse_kana_query = reverse_normalize_kana(params[:q])

    @q = current_user.tasks.ransack(title_cont_any: [kana_query, reverse_kana_query])
    @q.sorts = ["start_date asc", "end_date asc"] if @q.sorts.empty?

    filter_tasks_by_progress(@q.result(distinct: true), progress)
  end

  def tasks_ransack_from_milestone(milestone)
    @q = milestone.tasks.ransack(params[:q])
    @q.sorts = ["start_date asc", "end_date asc"] if @q.sorts.empty?
    @q.result(distinct: true).includes(:user)
  end

  def autocomplete_tasks_from_milestone(milestone, progress)
    query = params[:q]
    kana_query = normalize_kana(query)
    reverse_kana_query = reverse_normalize_kana(query)

    @q = milestone.tasks.ransack(title_cont_any: [kana_query, reverse_kana_query])
    @q.sorts = ["start_date asc", "end_date asc"] if @q.sorts.empty?

    filter_tasks_by_progress(@q.result(distinct: true), progress)
  end

  # オートコンプリート検索用(平仮名・カタカナのfuzzy検索)
  def autocomplete_by_title(class_name)
    query = params[:q] if params[:q].present?

    kana_query = normalize_kana(query)
    reverse_kana_query = reverse_normalize_kana(query)

    @q = if class_name == "milestone"
           current_user.milestones
         else
           current_user.tasks
         end

    @q = @q.ransack(title_cont_any: [kana_query, reverse_kana_query])
    @q.sorts = ["start_date asc", "end_date asc"] if @q.sorts.empty?

    if class_name == "milestone"
      @q.result(distinct: true).includes(:tasks)
    else
      @q.result(distinct: true).includes(:milestone)
    end
  end

  def ransack_by_title_and_description(class_name)
    @q = if class_name == "milestone"
           current_user.milestones
         else
           current_user.tasks
         end

    @q = @q.ransack(params[:q])
    @q.sorts = ["start_date asc", "end_date asc"] if @q.sorts.empty?

    if class_name == "milestone"
      @q.result(distinct: true).includes(:tasks)
    else
      @q.result(distinct: true).includes(:milestone)
    end
  end

  def filter_tasks_by_progress(result, progress)
    case progress.presence
    when "not_completed"
      result.not_completed.includes(:milestone)
    when "completed"
      result.completed.includes(:milestone)
    else
      result.includes(:milestone)
    end
  end
end
