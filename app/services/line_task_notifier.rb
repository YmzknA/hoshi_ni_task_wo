class LineTaskNotifier
  def initialize(user)
    @user = user
    @task_presenter = LineBot::TaskPresenter.new(user)
    @milestone_presenter = LineBot::MilestonePresenter.new(user)
  end

  def send_daily_notifications
    send_greeting_message
    send_upcoming_start_items_notification
    send_upcoming_deadline_items_notification
  end

  def send_greeting_message
    client.push_message(
      @user.uid,
      LineBot::MessageBuilder.text(
        "おはようございます🌅\
        \n本日 #{LineBot::MessageBuilder.to_short_date(Date.today)} のお知らせです！"
      )
    )
  end

  def send_upcoming_start_items_notification
    tasks, milestones = find_items_starting_soon
    message = "🚀 開始日が3日以内"
    client.push_message(@user.uid, build_notification_message(tasks, milestones, message))
  end

  def send_upcoming_deadline_items_notification
    tasks, milestones = find_items_with_nearby_deadlines
    message = "⏰ 終了日が前後3日以内"
    client.push_message(@user.uid, build_notification_message(tasks, milestones, message))
  end

  private

  def find_items_starting_soon
    tasks = @user.tasks.not_completed.order(:start_date).where(
      "start_date >= ? AND start_date <= ?", Date.today, Date.today + 3.days
    ).to_a.reject { |t| t.milestone.present? && t.milestone.completed? }

    milestones = @user.milestones.not_completed.where(
      "start_date >= ? AND start_date <= ?", Date.today, Date.today + 3.days
    ).order(:start_date)

    [tasks, milestones]
  end

  def find_items_with_nearby_deadlines
    tasks = @user.tasks.not_completed.order(:end_date).where(
      "end_date >= ? AND end_date <= ?", Date.today - 3.days, Date.today + 3.days
    ).to_a.reject { |t| t.milestone.present? && t.milestone.completed? }

    milestones = @user.milestones.not_completed.where(
      "end_date >= ? AND end_date <= ?", Date.today - 3.days, Date.today + 3.days
    ).order(:end_date)

    [tasks, milestones]
  end

  def build_notification_message(tasks, milestones, message)
    LineBot::MessageBuilder.text(
      "#{message}\
      \n\n#{@milestone_presenter.milestones_from_list(milestones)}\
      \n\n----------\
      \n\n#{@task_presenter.tasks_from_list(tasks)}"
    )
  end

  def client
    if Rails.env.development?
      Line::Bot::Client.new do |config|
        config.channel_secret = Rails.application.credentials.dig(:TEST_LINE_BOT, :SECRET)
        config.channel_token = Rails.application.credentials.dig(:TEST_LINE_BOT, :TOKEN)
      end
    else
      Line::Bot::Client.new do |config|
        config.channel_secret = Rails.application.credentials.dig(:LINE_BOT, :SECRET)
        config.channel_token = Rails.application.credentials.dig(:LINE_BOT, :TOKEN)
      end
    end
  end
end
