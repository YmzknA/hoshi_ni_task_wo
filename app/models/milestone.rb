class Milestone < ApplicationRecord
  has_many :tasks, dependent: :nullify
  belongs_to :user

  validates :title, presence: true
  validates :start_date, presence: true, if: -> { is_on_chart }
  validates :end_date, presence: true, if: -> { is_on_chart }

  enum progress: [:not_started, :in_progress, :completed]

  def update_progress
    self.progress = if tasks.empty?
                      logger.swim("tasks.empty? => true")
                      "not_started"
                    elsif tasks.any? { |t| t.progress == "in_progress" } || tasks.any? { |t| t.progress == "completed" }
                      logger.swim("tasks.any? => true")
                      "in_progress"
                    else
                      logger.swim("tasks.any? => false")
                      "not_started"
                    end
    save
  end
end
