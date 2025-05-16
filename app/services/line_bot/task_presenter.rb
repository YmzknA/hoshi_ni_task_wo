module LineBot
  class TaskPresenter
    def initialize(user)
      @user = user
    end

    def tasks_list
      return "ユーザーIDが取得できませんでした。" if @user.nil?

      tasks = @user.tasks.order(:start_date).reject { |t| t.milestone.present? && t.milestone.completed? }

      if tasks.empty?
        "タスクはありません！"
      else
        MessageBuilder.tasks_message(tasks)
      end
    end

    def tasks_for_milestone(milestone_title)
      milestone = @user.milestones.find_by(title: milestone_title)

      if milestone
        MessageBuilder.milestone_with_tasks_message(milestone)
      else
        "その星座は見つかりませんでした。"
      end
    end

    def tasks_milestones_for_search(search_word)
      search_word = ActiveRecord::Base.sanitize_sql_like(search_word)

      tasks = @user.tasks.where(
        "title ILIKE ?",
        "%#{search_word}%"
      ).order(:start_date)

      milestones = @user.milestones.where(
        "title ILIKE ?",
        "%#{search_word}%"
      ).order(:start_date)

      # tasksやmilestonesが空の場合の分岐はsearch_results_messageメソッド内で行う
      MessageBuilder.search_results_message(tasks, milestones)
    end
  end
end
