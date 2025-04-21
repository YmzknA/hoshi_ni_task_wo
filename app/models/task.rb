class Task < ApplicationRecord
  belongs_to :milestone, optional: true
  belongs_to :user

  validates :title, presence: true
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
end
