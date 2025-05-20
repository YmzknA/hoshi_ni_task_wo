namespace :push_line do
  desc "LINEで開始日・終了日が近いタスクとマイルストーンの通知を送信"
  task send_daily_task_notifications: :environment do
    User.all.each do |user|
      next if user.uid.nil?

      notifier = LineTaskNotifier.new(user)
      notifier.send_daily_notifications
    end
  end
end
