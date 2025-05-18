namespace :push_line do
  desc "LINEBOT：期限が直近のアプリの通知"
  task push_line_message_trash: :environment do
    message = {
      type: "text",
      text: "ここに生成したメッセージを入れる"
    }
    client = Line::Bot::Client.new do |config|
      config.channel_secret = Rails.application.credentials.dig(:LINE_BOT, :SECRET)
      config.channel_token = Rails.application.credentials.dig(:LINE_BOT, :TOKEN)
    end

    User.all.each do |user|
      client.push_message(user.uid, message)
    end
  end
end
