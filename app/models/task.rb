class Task < ApplicationRecord
  belongs_to :milestone, optional: true
  belongs_to :user

  validates :title, presence: true, length: { maximum: 25 }

  validate :start_date_check
  validate :end_date_check

  validates :progress, presence: true

  enum progress: [:not_started, :in_progress, :completed]

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

  private

  def start_date_check
    if start_date.present?
      errors.add(:start_date, "start_dateは3ヶ月以上前の日付であってはなりません") if start_date < 3.months.ago
      errors.add(:start_date, "start_dateは6ヶ月以上先の日付であってはなりません") if start_date > 6.months.from_now
    end
    start_before_end = start_date.present? && end_date.present? && start_date >= end_date
    errors.add(:start_date, "start_dateはend_dateより前か同じ日付でなければなりません") if start_before_end
  end

  def end_date_check
    if end_date.present?
      errors.add(:end_date, "end_dateは過去の日付であってはなりません") if end_date < Date.today
      errors.add(:end_date, "end_dateは6ヶ月以上先の日付であってはなりません") if end_date > 6.months.from_now
    end
    start_before_end = start_date.present? && end_date.present? && start_date >= end_date
    errors.add(:end_date, "end_dateはstart_dateより前か同じ日付でなければなりません") if start_before_end
  end
end
