class LineTaskNotifier
  # 定数定義
  CHAR_LIMIT = 4900
  MESSAGE_DELAY = 0.5
  USER_DELAY = 0.5

  def initialize(user)
    @user = user
    @task_presenter = LineBot::TaskPresenter.new(user)
    @milestone_presenter = LineBot::MilestonePresenter.new(user)
  end

  def send_daily_notifications
    messages_sent = 0

    # 挨拶メッセージを送信
    begin
      send_greeting_message
      messages_sent += 1
      Rails.logger.info "Greeting message sent to user #{@user.id}"
    rescue StandardError => e
      Rails.logger.error "Failed to send greeting message to user #{@user.id}: #{e.message}"
    end

    sleep(MESSAGE_DELAY) if messages_sent.positive? # API制限回避のため少し待機

    # ▽▲▽▲▽▲▽▲▽▲▽▲▽▲▽▲▽▲▽▲▽▲▽▲▽▲▽▲▽▲▽▲▽▲▽▲▽▲▽▲

    # 3日以内に開始するタスクとマイルストーンの通知を送信
    begin
      send_upcoming_start_items_notification
      messages_sent += 1
      Rails.logger.info "Start items notification sent to user #{@user.id}"
    rescue StandardError => e
      Rails.logger.error "Failed to send start items notification to user #{@user.id}: #{e.message}"
    end

    sleep(MESSAGE_DELAY) if messages_sent > 1 # API制限回避のため少し待機

    # ▽▲▽▲▽▲▽▲▽▲▽▲▽▲▽▲▽▲▽▲▽▲▽▲▽▲▽▲▽▲▽▲▽▲▽▲▽▲▽▲

    # 終了日が前後3日以内のタスクとマイルストーンの通知を送信
    begin
      send_upcoming_deadline_items_notification
      messages_sent += 1
      Rails.logger.info "Deadline notification sent to user #{@user.id}"
    rescue StandardError => e
      Rails.logger.error "Failed to send deadline notification to user #{@user.id}: #{e.message}"
    end

    Rails.logger.info "Total messages sent to user #{@user.id}: #{messages_sent}/3"
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
    content = message.to_s

    # 星座のメッセージ
    milestone_text = @milestone_presenter.milestones_from_list(milestones)
    content += "\n\n#{milestone_text}" if milestone_text.present?

    # 分割線
    content += "\n\n----------" if milestone_text.present? || tasks.any?

    # タスクのメッセージ
    task_text = @task_presenter.tasks_from_list(tasks)
    content += "\n\n#{task_text}" if task_text.present?

    # LINEの文字数制限（5000文字）をチェック
    if content.length > CHAR_LIMIT # 余裕を持って4900文字に制限
      content = "#{content[0..CHAR_LIMIT]}...\n\n📱 文字数制限により一部省略しました\n残りの詳細はアプリでご確認ください"
    end

    LineBot::MessageBuilder.text(content)
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
