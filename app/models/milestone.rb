class Milestone < ApplicationRecord
  has_many :tasks, dependent: :nullify
  belongs_to :user
  belongs_to :constellation, optional: true

  validates :title, presence: true
  validates :start_date, presence: true, if: -> { is_on_chart }
  validates :end_date, presence: true, if: -> { is_on_chart }
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
end
