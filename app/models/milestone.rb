class Milestone < ApplicationRecord
  has_many :tasks, dependent: :nullify
  belongs_to :user
  belongs_to :constellation, optional: true

  # Validations
  validates :title, presence: true
  validates :description, length: { maximum: 150 }, allow_blank: true

  validates :start_date, presence: true, if: -> { is_on_chart }
  validate :start_date_check

  validates :end_date, presence: true, if: -> { is_on_chart }
  validate :end_date_check

  validate :tasks_date_check, if: -> { is_on_chart }

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

  # ######################################
  # スコープ
  # ######################################
  scope :on_chart, -> { where(is_on_chart: true) }
  scope :not_completed, -> { where(progress: [:not_started, :in_progress]) }
  scope :start_date_asc, -> { order(start_date: :asc) }

  # ######################################
  # メソッド
  # ######################################
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

  def public?
    is_public == true
  end

  def on_chart?
    is_on_chart == true
  end

  def copy(set_date)
    copy = dup
    copy.title = "#{title}_copy"
    copy.progress = "not_started"
    copy.completed_comment = nil
    copy.constellation = nil
    copy.created_at = Time.current

    if copy.start_date.present? && copy.end_date.present?
      date_diff = (copy.end_date - copy.start_date).to_i

      copy.start_date = set_date
      copy.end_date = set_date.to_date + date_diff.days
    elsif copy.start_date.present?
      copy.start_date = set_date
    elsif copy.end_date.present?
      copy.end_date = set_date
    end
    # 両方nilの場合は何もしない

    copy
  end

  # ######################################
  # privateメソッド
  # ######################################
  private

  def start_date_check
    start_before_end = start_date.present? && end_date.present? && start_date >= end_date
    errors.add(:start_date, "は終了日より前の日付を設定してください") if start_before_end
  end

  def end_date_check
    end_after_start = start_date.present? && end_date.present? && start_date >= end_date
    errors.add(:end_date, "は開始日より後の日付を設定してください") if end_after_start
  end

  def tasks_date_check
    return unless tasks.any?

    tasks.each do |task|
      validate_task_start_date(task) unless task.start_date.blank?

      validate_task_end_date(task) unless task.end_date.blank?
    end
  end

  def validate_task_start_date(task)
    errors.add(:start_date, "は紐づくタスクの開始日以前に設定してください。タスクは星座の期間内に収まる必要があります") if task.start_date < start_date
  end

  def validate_task_end_date(task)
    errors.add(:end_date, "は紐づくタスクの終了日以降に設定してください。タスクは星座の期間内に収まる必要があります") if task.end_date > end_date
  end
end
