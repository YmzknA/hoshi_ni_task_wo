class Task < ApplicationRecord
  belongs_to :milestone, optional: true
  belongs_to :user

  validates :title, presence: true, length: { maximum: 25 }

  validate :start_date_check
  validate :end_date_check
  # milestoneがis_on_chartがtrueの場合、マイルストーンの開始日と終了日はタスクの開始日と終了日の中でなければならない
  validate :milestone_start_date_check
  validate :milestone_end_date_check

  validates :progress, presence: true

  enum progress: [:not_started, :in_progress, :completed]

  # start_dateとend_dateのどちらかがnilのものを弾くscope
  scope :valid_dates, -> { where.not(start_date: nil, end_date: nil) }
  scope :completed, -> { where(progress: :completed) }
  scope :in_progress, -> { where(progress: :in_progress) }
  scope :not_started, -> { where(progress: :not_started) }
  scope :created_at_desc, -> { order(created_at: :desc) }

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

  def in_progress?
    progress == "in_progress"
  end

  def not_started?
    progress == "not_started"
  end

  private

  def start_date_check
    start_before_end = start_date.present? && end_date.present? && start_date > end_date
    errors.add(:start_date, "はEnd date以前か、同じでなければなりません") if start_before_end
  end

  def end_date_check
    start_before_end = start_date.present? && end_date.present? && start_date > end_date
    errors.add(:end_date, "はStart date以前か、同じでなければなりません") if start_before_end
  end

  def milestone_start_date_check
    return unless milestone
    return if milestone.is_on_chart == false

    errors.add(:start_date, "または End dateは、紐づける星座がチャートに表示されているとき、存在しなければなりません。") if start_date.blank? && end_date.blank?

    errors.add(:start_date, "は星座の開始日と同じか前でなければなりません") if start_date.present? && milestone.start_date > start_date
  end

  def milestone_end_date_check
    return unless milestone
    return if milestone.is_on_chart == false

    errors.add(:end_date, "または Start dateは、紐づける星座がチャートに表示されているとき、存在しなければなりません。") if start_date.blank? && end_date.blank?

    errors.add(:end_date, "は星座の終了日と同じか、後でなければなりません") if end_date.present? && milestone.end_date < end_date
  end
end
