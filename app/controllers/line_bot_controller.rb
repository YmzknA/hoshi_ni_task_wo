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
      setup(event)
      reply_message = reply
      client.reply_message(event["replyToken"], reply_message)
    end
  end

  private

  def client
    @client ||= if Rails.env.development?
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

  def reply
    case @event
    when Line::Bot::Event::Message
      case @event.type
      when Line::Bot::Event::MessageType::Text
        handle_message_event
      end
    end
  end

  def handle_message_event
    case @event.message["text"]
    when "タスク確認"
      LineBot::MessageBuilder.text(@task_presenter.tasks_list)
    when "星座確認"
      LineBot::MessageBuilder.text(@milestone_presenter.milestones_list)
    when "両方確認"
      LineBot::MessageBuilder.text(
        "#{@milestone_presenter.milestones_list}\n\n----------\n\n#{@task_presenter.tasks_list}"
      )
    when "星座の名前で確認"
      Rails.cache.write("user_#{@user_id}_step", "tasks_for_milestone", expires_in: 1.minutes)
      LineBot::MessageBuilder.text(
        "🌟 続いて、星座のタイトルを送信してください。\n\n↓星座のタイトル一覧↓\n#{@milestone_presenter.milestones_title_list}"
      )
    when "検索"
      Rails.cache.write("user_#{@user_id}_step", "search_tasks", expires_in: 1.minutes)
      LineBot::MessageBuilder.text("🔍 続いて、検索ワードを送信してください。\nタイトルに含まれている文字から検索します")
    else
      handle_other_message
    end
  end

  def handle_other_message
    # tasks_for_milestoneとsearch_tasksのステップにいる場合は、メッセージを処理する
    if Rails.cache.read("user_#{@user_id}_step") == "tasks_for_milestone"
      handle_milestone_selection
    elsif Rails.cache.read("user_#{@user_id}_step") == "search_tasks"
      handle_search_tasks
    else
      LineBot::MessageBuilder.text("メニューから選択してください")
    end
  end

  def handle_milestone_selection
    milestone_title = @event.message["text"]
    LineBot::MessageBuilder.text(@task_presenter.tasks_for_milestone(milestone_title))
  end

  def handle_search_tasks
    search_word = @event.message["text"]
    LineBot::MessageBuilder.text(@task_presenter.tasks_milestones_for_search(search_word))
  end

  def setup(event)
    @event = event
    @user_id = event["source"]["userId"]
    @user = User.find_by(uid: @user_id)
    @task_presenter = LineBot::TaskPresenter.new(@user)
    @milestone_presenter = LineBot::MilestonePresenter.new(@user)
  end
end
