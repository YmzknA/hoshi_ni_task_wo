module LineBot
  class MilestonePresenter
    def initialize(user)
      @user = user
    end

    def milestones_list
      return "ユーザーが見つかりません" unless @user

      milestones = active_milestones
      return "星座はまだありません！" if milestones.empty?

      MessageBuilder.milestones_message(milestones)
    end

    def milestones_title_list
      return "ユーザーが見つかりません" unless @user

      milestones = active_milestones
      return "星座はまだありません！" if milestones.empty?

      MessageBuilder.milestones_title_message(milestones)
    end

    private

    def active_milestones
      @user.milestones.order(:start_date).where.not(progress: "completed")
    end
  end
end
