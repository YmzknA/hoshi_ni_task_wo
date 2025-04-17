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
end
