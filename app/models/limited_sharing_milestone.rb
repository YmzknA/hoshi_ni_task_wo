class LimitedSharingMilestone < ApplicationRecord
  include NanoidGenerator

  belongs_to :user
  belongs_to :constellation, optional: true
  has_many :tasks, dependent: :destroy, class_name: "LimitedSharingTask"

  validates :title, presence: true
  validates :progress, presence: true
  validates :color, presence: true
  validates :user_id, presence: true
  validates :is_on_chart, presence: true

  enum progress: [:not_started, :in_progress, :completed]

  # ######################################
  # メソッド
  # ######################################
  def initialize(attributes = nil)
    super
    set_id
  end

  def completed_tasks_percentage
    tasks = self.tasks
    return 0 if tasks.empty?

    completed_tasks = tasks.select { |task| task.progress == "completed" }.length
    total_tasks = tasks.length

    n = completed_tasks.to_f / total_tasks
    (n * 100).round
  end
end
