class Task < ApplicationRecord
  belongs_to :milestone, optional: true
  belongs_to :user

  validates :title, presence: true

  enum progress: [:not_started, :in_progress, :completed]
end
