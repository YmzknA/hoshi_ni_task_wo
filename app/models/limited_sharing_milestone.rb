class LimitedSharingMilestone < ActiveRecord::Base
  include NanoIdGenerator

  belongs_to :user
  belongs_to :constellation, optional: true
  has_many :limited_sharing_tasks, dependent: :destroy

  validates :title, presence: true
  validates :progress, presence: true
  validates :color, presence: true
  validates :user_id, presence: true
  validates :is_on_chart, presence: true

  enum progress: { not_started: 0, in_progress: 1, completed: 2 }
end
