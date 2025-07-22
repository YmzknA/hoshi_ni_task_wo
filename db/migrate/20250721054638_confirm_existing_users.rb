class ConfirmExistingUsers < ActiveRecord::Migration[7.2]
  def up
    # 既存のユーザー（confirmed_at が nil のユーザー）全員を認証済みにする
    User.where(confirmed_at: nil).update_all(confirmed_at: Time.current)
  end

  def down
    # ロールバック時は何もしない（既存ユーザーの状態を元に戻すのは危険）
    # 必要に応じて手動で対応
  end
end
