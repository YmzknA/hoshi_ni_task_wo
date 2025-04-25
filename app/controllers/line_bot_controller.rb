class LineBotController < ApplicationController
  protect_from_forgery except: [:callback]

  def callback
    body = request.body.read
    signature = request.env["HTTP_X_LINE_SIGNATURE"]
    unless client.validate_signature(body, signature)
      head :bad_request
      return
    end

    events = client.parse_events_from(body)
    events.each do |event|
      client.reply_message(event["replyToken"], message(event))
    end
  end

  private

  def client
    @client ||= Line::Bot::Client.new do |config|
      config.channel_secret = Rails.application.credentials.dig(:LINE_BOT, :SECRET)
      config.channel_token = Rails.application.credentials.dig(:LINE_BOT, :TOKEN)
    end
  end

  def message(event)
    case event
    when Line::Bot::Event::Message
      case event.type
      when Line::Bot::Event::MessageType::Text
        handle_message_event(event)
      end
    end
  end

  def handle_message_event(event)
    case event.message["text"]
    when "タスクを確認"
      {
        type: "text",
        text: get_all_milestones_and_tasks(event)
      }
    else
      {
        type: "text",
        text: "タスクを確認するには「タスクを確認」と送信してください。"
      }
    end
  end

  # 星座とタスクの両方のリストを取得して結合する
  def get_all_milestones_and_tasks(event)
    user = get_user(event)

    if user.nil?
      "ユーザーIDが取得できませんでした。"
    else
      "#{get_milestones_list(event)} \n\n ---------- \n\n #{get_tasks_list(event)}"
    end
  end

  # ユーザーを取得するメソッド
  def get_user(event)
    user_id = event["source"]["userId"]
    user = User.find_by(uid: user_id)

    if user.nil?
      nil
    else
      user
    end
  end

  # 星座のリストを取得するメソッド
  def get_milestones_list(event)
    user = get_user(event)
    milestones = user.milestones.order(:start_date).where.not(progress: "completed")

    if user.nil?
      "ユーザーIDが取得できませんでした。"
    elsif milestones.empty?
      "星座はまだありません！"
    else
      messages = milestones.map do |milestone|
        is_first = milestone == milestones.first
        start_date = to_short_date(milestone.start_date)
        end_date = to_short_date(milestone.end_date)
        tasks_count = milestone.tasks.count

        "#{is_first ? '' : "\n"}🌟：#{milestone.title}\
        \n   📝：#{tasks_count}つ\
        \n   #{start_date} ~ #{end_date}"
      end
      messages.join("\n")
    end
  end

  # タスクのリストを取得するメソッド
  def get_tasks_list(event)
    user = get_user(event)
    tasks = user.tasks.order(:start_date).reject { |t| t&.milestone_completed? }

    if user.nil?
      "ユーザーIDが取得できませんでした。"
    elsif tasks.empty?
      "タスクはありません！"
    else
      tasks_message(tasks)
    end
  end

  def tasks_message(tasks)
    tasks.map do |task|
      is_first = task == tasks.first
      start_date = to_short_date(task.start_date)
      end_date = to_short_date(task.end_date)
      task_milestone_title = task.milestone&.title || "---"
      progress = get_progress(task)

      "#{is_first ? '' : "\n"}📝：#{task.title} - #{progress}\
      \n   🌟：#{task_milestone_title}\
      \n    #{start_date} ~ #{end_date}"
    end.join("\n")
  end

  # タスクの進捗を取得するメソッド
  def get_progress(task)
    case task.progress
    when "not_started"
      "🍵 未着手"
    when "in_progress"
      "👉 進行中"
    when "completed"
      "✅ 完了"
    else
      "❓不明な進捗"
    end
  end

  # 曜日を取得するメソッド
  def day_of_week(date)
    return if date.nil?

    day_name_ja = %w[日 月 火 水 木 金 土]

    d = date.to_date.wday

    day_name_ja[d]
  end

  # 日付を短縮形式で表示するメソッド
  def to_short_date(date)
    return if date.nil?

    "#{date.mon}/#{date.mday} (#{day_of_week(date)})"
  end
end
