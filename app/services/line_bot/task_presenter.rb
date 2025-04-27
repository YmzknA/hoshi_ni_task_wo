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
  end
end
