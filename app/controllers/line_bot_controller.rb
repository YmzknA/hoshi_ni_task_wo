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

    user_id = events.first["source"]["userId"]
    user = User.find_by(uid: user_id)
    tasks = user.tasks
    message = ""

    tasks.each do |task|
      message += "Task: #{task.title},
                  progress: #{task.progress},
                  start_date: #{task.start_date},
                  end_date: #{task.end_date}"
    end

    events.each do |event|
      case event
      when Line::Bot::Event::Message
        reply_token = event["replyToken"]
        reply_text(reply_token, message)
      when Line::Bot::Event::Follow
        handle_follow(event)
      end
    end

    head :ok
  end

  private

  def client
    @client ||= Line::Bot::Client.new do |config|
      config.channel_secret = Rails.application.credentials.dig(:LINE_BOT, :SECRET)
      config.channel_token = Rails.application.credentials.dig(:LINE_BOT, :TOKEN)
    end
  end

  def reply_text(reply_token, text)
    message = {
      type: "text",
      text: text
    }
    client.reply_message(reply_token, message)
  end
end
