namespace :push_line do
  desc "LINEで開始日・終了日が近いタスクとマイルストーンの通知を送信"
  task send_daily_task_notifications: :environment do
    success_count = 0
    error_count = 0

    User.notifications_enabled.each do |user|
      next if user.uid.nil?

      Rails.logger.info "Starting notification for user #{user.id}"
      notifier = LineTaskNotifier.new(user)
      notifier.send_daily_notifications
      success_count += 1
      Rails.logger.info "Successfully sent notification to user #{user.id}"

      # API制限回避のため1秒待機
      sleep(1)
    rescue StandardError => e
      error_count += 1
      Rails.logger.error "Failed to send notification to user #{user.id}: #{e.class} - #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      # エラーが起きても次のユーザーの処理を続行
      next
    end

    Rails.logger.info "Notification task completed. Success: #{success_count}, Errors: #{error_count}"
  end
end
