class LimitedSharingTask < ApplicationRecord
  include NanoidGenerator

  belongs_to :milestone, class_name: "LimitedSharingMilestone", foreign_key: "limited_sharing_milestone_id"
  belongs_to :user

  validates :title, presence: true
  validates :progress, presence: true
  validates :limited_sharing_milestone_id, presence: true

  enum progress: [:not_started, :in_progress, :completed]

  # dateが両方nilのものを弾くscope
  scope :valid_dates_nil, -> { where.not(start_date: nil, end_date: nil) }
  scope :start_date_asc, -> { order(start_date: :asc) }

  # ######################################
  # メソッド
  # ######################################
  def initialize(attributes = nil)
    super
    set_id
  end

  def milestone_completed?
    milestone&.progress == "completed"
  end

  def completed?
    progress == "completed"
  end

  def in_progress?
    progress == "in_progress"
  end

  def not_started?
    progress == "not_started"
  end
end
