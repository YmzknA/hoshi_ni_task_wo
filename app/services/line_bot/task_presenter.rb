module LineBot
  class TaskPresenter
    def initialize(user)
      @user = user
    end

    def tasks_list
      tasks = @user.tasks.order(:start_date).reject { |t| t&.milestone_completed? }

      if @user.nil?
        "ユーザーIDが取得できませんでした。"
      elsif tasks.empty?
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
