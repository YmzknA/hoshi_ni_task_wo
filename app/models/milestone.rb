class Milestone < ApplicationRecord
  has_many :tasks, dependent: :nullify
  belongs_to :user
  belongs_to :constellation, optional: true

  # Validations
  validates :title, presence: true

  validates :start_date, presence: true, if: -> { is_on_chart }
  validate :start_date_check

  validates :end_date, presence: true, if: -> { is_on_chart }
  validate :end_date_check

  validates :progress, presence: true
  validates :color, presence: true

  validates :completed_comment, length: { maximum: 50 }, allow_blank: true

  validates :is_public, inclusion: { in: [true, false] }
  validates :is_on_chart, inclusion: { in: [true, false] }

  # Enum for progress status
  # :not_started = 0
  # :in_progress = 1
  # :completed = 2
  enum progress: [:not_started, :in_progress, :completed]

  def completed_tasks_percentage
    tasks = self.tasks
    return 0 if tasks.empty?

    completed_tasks = tasks.select { |task| task.progress == "completed" }.length
    total_tasks = tasks.length

    n = completed_tasks.to_f / total_tasks
    (n * 100).round
  end

  def update_progress
    self.progress = if tasks.empty?
                      "not_started"
                    elsif tasks.any? { |t| t.progress == "in_progress" } || tasks.any? { |t| t.progress == "completed" }
                      "in_progress"
                    else
                      "not_started"
                    end
    save
  end

  private

  def start_date_check
    if start_date.present?
      errors.add(:start_date, "start_dateは1ヶ月以上前の日付であってはなりません") if start_date < 1.months.ago
      errors.add(:start_date, "start_dateは6ヶ月以上先の日付であってはなりません") if start_date > 6.months.from_now
    end
    start_before_end = start_date.present? && end_date.present? && start_date >= end_date
    errors.add(:start_date, "start_dateはend_dateより前でなければなりません") if start_before_end
  end

  def end_date_check
    if end_date.present?
      errors.add(:end_date, "end_dateは過去の日付であってはなりません") if end_date < Date.today
      errors.add(:end_date, "end_dateは6ヶ月以上先の日付であってはなりません") if end_date > 6.months.from_now
    end
    end_after_start = start_date.present? && end_date.present? && start_date >= end_date
    errors.add(:end_date, "end_dateはstart_dateより後でなければなりません") if end_after_start
  end
end
