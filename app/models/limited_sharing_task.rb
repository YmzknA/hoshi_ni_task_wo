class LimitedSharingTask < ApplicationRecord
  include NanoIdGenerator

  belongs_to :limited_sharing_milestone

  validates :title, presence: true
  validates :progress, presence: true
  validates :limited_sharing_milestone_id, presence: true

  enum progress: { not_started: 0, in_progress: 1, completed: 2 }
end
