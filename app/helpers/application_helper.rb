module ApplicationHelper
  def current_user?(user)
    user && user == current_user
  end

  def day_of_week(date)
    return if date.nil?

    day_name_ja = %w[日 月 火 水 木 金 土]

    d = date.to_date.wday

    day_name_ja[d]
  end

  def to_short_date(date)
    return if date.nil?

    "#{date.mon}/#{date.mday} (#{day_of_week(date)})"
  end

  # タスクの進捗を取得するメソッド
  def get_progress_message(task)
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

  def default_meta_tags
    {
      site: "星にタスクを",
      title: "星にタスクを",
      reverse: true,
      charset: "utf-8",
      description: "星にタスクをは、縦軸チャートでタスクを可視化する新しいタスク管理アプリです。",
      canonical: request.original_url,
      og: {
        site_name: "星にタスクを",
        title: "星にタスクを",
        description: "星にタスクをは、縦軸チャートでタスクを可視化する新しいタスク管理アプリです。",
        type: "website",
        url: request.original_url,
        image: image_url("default_ogp.png"),
        locale: "ja-JP"
      },
      twitter: {
        card: "summary_large_image",
        image: image_url("default_ogp.png")
      }
    }
  end
end
