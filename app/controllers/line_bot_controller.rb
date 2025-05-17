# rubocop:disable Metrics/ClassLength
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

  # rubocop:disable Metrics/CyclomaticComplexity
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
      cache_write("step", "tasks_for_milestone", 1.minutes)
      LineBot::MessageBuilder.text(
        "🌟 続いて、星座のタイトルを送信してください。\n\n↓星座のタイトル一覧↓\n#{@milestone_presenter.milestones_title_list}"
      )
    when "タイトルから検索"
      cache_write("step", "search_tasks_milestones", 1.minutes)
      LineBot::MessageBuilder.text("🔍 続いて、検索ワードを送信してください。\nタイトルに含まれている文字から検索します")
    when "タスクの開始日変更"
      cache_write("step", "select_task_edit_start_date", 2.minutes)
      LineBot::MessageBuilder.text("どのタスクの開始日を変更しますか？\nタイトルを入力してください。")
    when "タスクの終了日変更"
      cache_write("step", "select_task_edit_end_date", 2.minutes)
      LineBot::MessageBuilder.text("どのタスクの終了日を変更しますか？\nタイトルを入力してください。")
    when "メニュー一覧"
      LineBot::MenuListBuilder.menu_list("ご利用になりたいメニューを選んでください。\n\nはじめからやり直したい場合は「はじめから」と入力してください。")
    when "はじめから"
      cache_delete("step")
      cache_delete("task_id")
      cache_delete("task_select")
      LineBot::MenuListBuilder.menu_list("はじめからやり直します。\n\nご利用になりたいメニューを選んでください。\n\nはじめからやり直したい場合は「はじめから」と入力してください。")
    else
      handle_other_message
    end
  end
  # rubocop:enable Metrics/CyclomaticComplexity

  def handle_other_message
    # ステップがある場合は、ステップに応じた処理を行う
    if cache_read("step").present?
      handle_cache_step
    else
      LineBot::MenuListBuilder.menu_list("ご利用になりたいメニューを選んでください。\n\nはじめからやり直したい場合は「はじめから」と入力してください。")
    end
  end

  def handle_cache_step
    case cache_read("step")
    when "tasks_for_milestone"
      handle_milestone_selection # 星座の名前で確認
    when  "search_tasks_milestones"
      handle_search_tasks_milestones # タイトルか詳細から検索
    when  "select_task_edit_start_date"
      handle_select_task_edit_date("start_date") # タスクの開始日変更
    when "select_task_edit_end_date"
      handle_select_task_edit_date("end_date") # タスクの終了日変更
    when "change_task_start_date"
      task_date_change("start_date") # タスクの開始日変更日付選択
    when "change_task_end_date"
      task_date_change("end_date") # タスクの終了日変更日付選択
    else
      cache_delete("step")
      LineBot::MenuListBuilder.menu_list("エラーが発生しました。はじめからやり直します。\
                                         \n\nご利用になりたいメニューを選んでください。\
                                         \n\nはじめからやり直したい場合は「はじめから」と入力してください。")
    end
  end

  def handle_milestone_selection
    milestone_title = @event.message["text"]
    LineBot::MessageBuilder.text(@task_presenter.tasks_for_milestone(milestone_title))
  end

  def handle_search_tasks_milestones
    search_word = @event.message["text"]
    LineBot::MessageBuilder.text(@task_presenter.tasks_milestones_info_from_search(search_word))
  end

  def handle_select_task_edit_date(which_date_change)
    # id選択状態かキャッシュで確認
    if cache_read("task_select") == "select_task_edit_from_id"
      task_id = @event.message["text"]
      tasks = @task_presenter.tasks_from_id(task_id) # idでさがすので最大1つしか返ってこない
    else
      title = @event.message["text"]
      tasks = @task_presenter.tasks_from_title(title)
    end

    # 空の場合
    if tasks.empty?
      LineBot::MessageBuilder.text("📝 タスクが見つかりませんでした")

    # タスクが1つ
    elsif tasks.length == 1
      # どちらの日付を変更するかキャッシュに保存
      cache_write("step", "change_task_#{which_date_change}", 1.minutes)

      # タスクのIDをキャッシュに保存
      cache_write("task_id", tasks.first.id, 1.minutes)
      LineBot::MessageBuilder.text(LineBot::MessageBuilder.task_change_date_message(tasks.first))
    else

      # タスクが複数ある場合、どのタスクを変更するか選択させる
      # キャッシュにidから選択状態であることを保存
      cache_write("task_select", "select_task_edit_from_id", 1.minutes)
      LineBot::MessageBuilder.text(LineBot::MessageBuilder.tasks_list_for_change(tasks))
    end
  end

  # タスクの日付を変更するメソッド
  def task_date_change(which_date_change)
    date_string = @event.message["text"]
    task_id = cache_read("task_id")
    task = Task.find(task_id)

    if task.present?
      LineBot::MessageBuilder.text(
        @task_presenter.update_task_date_and_get_response(task, date_string, which_date_change)
      )
    else
      LineBot::MessageBuilder.text("❌📝 日付の変更に失敗しました")
    end
  end

  def setup(event)
    @event = event
    @user_id = event["source"]["userId"]
    @user = User.find_by(uid: @user_id)
    @task_presenter = LineBot::TaskPresenter.new(@user)
    @milestone_presenter = LineBot::MilestonePresenter.new(@user)
  end

  def secure_cache_key(suffix)
    # 自前で用意したCACHE_SALTを使ってHMACを生成
    salt = Rails.application.credentials[:CACHE_SALT]
    digest = OpenSSL::HMAC.hexdigest("SHA256", salt, @user_id.to_s)
    "user_#{digest}_#{suffix}"
  end

  def cache_write(suffix, value, cache_time)
    Rails.cache.write(secure_cache_key(suffix), value, expires_in: cache_time)
  end

  def cache_read(suffix)
    Rails.cache.read(secure_cache_key(suffix))
  end

  def cache_delete(suffix)
    Rails.cache.delete(secure_cache_key(suffix))
  end
end
# rubocop:enable Metrics/ClassLength
