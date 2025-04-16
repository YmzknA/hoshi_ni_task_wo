class Milestone < ApplicationRecord
  has_many :tasks, dependent: :nullify
  belongs_to :user

  validates :title, presence: true
  validates :start_date, presence: true, if: -> { is_on_chart }
  validates :end_date, presence: true, if: -> { is_on_chart }

  enum progress: [:not_started, :in_progress, :completed]

  def completed_tasks_percentage
    tasks = self.tasks
    return 0 if tasks.empty?

    completed_tasks = tasks.select { |task| task.progress == "completed" }.length
    total_tasks = tasks.length

    n = completed_tasks.to_f / total_tasks
    percentage = (n * 100).round
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
