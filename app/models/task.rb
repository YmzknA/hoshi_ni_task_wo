class Task < ApplicationRecord
  belongs_to :milestone, optional: true
  belongs_to :user

  validates :title, presence: true, length: { maximum: 25 }

  validate :start_date_check
  validate :end_date_check
  # milestoneがis_on_chartがtrueの場合、マイルストーンの開始日と終了日はタスクの開始日と終了日の中でなければならない
  validate :milestone_date_check

  validates :progress, presence: true

  enum progress: [:not_started, :in_progress, :completed]

  # start_dateとend_dateのどちらかがnilのものを弾くscope
  scope :valid_dates, -> { where.not(start_date: nil, end_date: nil) }
  scope :start_order_asc, -> { order(start_date: :asc) }
  scope :completed, -> { where(progress: :completed) }

  def next_progress
    case progress
    when "not_started"
      "in_progress"
    when "in_progress"
      "completed"
    else
      "not_started"
    end
  end

  def milestone_completed?
    milestone&.progress == "completed"
  end

  def completed?
    progress == "completed"
  end

  private

  def start_date_check
    start_before_end = start_date.present? && end_date.present? && start_date >= end_date
    errors.add(:start_date, "start_dateはend_dateより前でなければなりません") if start_before_end
  end

  def end_date_check
    start_before_end = start_date.present? && end_date.present? && start_date >= end_date
    errors.add(:end_date, "end_dateはstart_dateより前でなければなりません") if start_before_end
  end

  def milestone_date_check
    return unless milestone
    return if milestone.is_on_chart == false

    if start_date.blank? || end_date.blank?
      errors.add(:start_date, "紐づける星座がチャートに表示されているとき、Start Dateが存在しなければなりません。")
      errors.add(:end_date, "紐づける星座がチャートに表示されているとき、End Dateが存在しなければなりません。")
      return
    end

    errors.add(:start_date, "星座の開始日はタスクの開始日と同じか前でなければなりません") if milestone.start_date > start_date

    errors.add(:end_date, "星座の終了日はタスクの終了日と同じか、後でなければなりません") if milestone.end_date < end_date
  end
end
