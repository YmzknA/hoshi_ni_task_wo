class Task < ApplicationRecord
  belongs_to :milestone, optional: true
  belongs_to :user

  validates :title, presence: true, length: { maximum: 25 }
  validates :description, length: { maximum: 150 }, allow_blank: true

  validate :start_date_check
  validate :end_date_check
  # milestoneがis_on_chartがtrueの場合、マイルストーンの開始日と終了日はタスクの開始日と終了日の中でなければならない
  validate :milestone_start_date_check
  validate :milestone_end_date_check

  validates :progress, presence: true

  enum progress: [:not_started, :in_progress, :completed]

  # ######################################
  # スコープ
  # ######################################
  # start_dateとend_dateのどちらかがnilのものを弾くscope
  scope :valid_dates_nil, -> { where.not(start_date: nil, end_date: nil) }
  scope :not_started, -> { where(progress: :not_started) }
  scope :in_progress, -> { where(progress: :in_progress) }
  scope :completed, -> { where(progress: :completed) }
  scope :not_completed, -> { where.not(progress: :completed) }
  scope :created_at_desc, -> { order(created_at: :desc) }
  scope :start_date_asc, -> { order(start_date: :asc) }

  # ######################################
  # メソッド
  # ######################################
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

  def completed?
    progress == "completed"
  end

  def in_progress?
    progress == "in_progress"
  end

  def not_started?
    progress == "not_started"
  end

  def copy(set_date)
    copy = dup

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

  def self.ransackable_attributes(_auth_object = nil)
    %w[created_at description end_date id milestone_id progress start_date title updated_at user_id]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[milestone user]
  end

  # ######################################
  # privateメソッド
  # ######################################
  private

  def start_date_check
    start_before_end = start_date.present? && end_date.present? && start_date > end_date
    errors.add(:start_date, "は終了日と同じか、それより前の日付にしてください") if start_before_end
  end

  def end_date_check
    start_before_end = start_date.present? && end_date.present? && start_date > end_date
    errors.add(:end_date, "は開始日と同じか、それより後の日付にしてください") if start_before_end
  end

  def milestone_start_date_check
    return unless milestone
    return if milestone.is_on_chart == false

    errors.add(:start_date, "または終了日のいずれかを設定してください。チャートに表示される星座のタスクには日付が必要です") if start_date.blank? && end_date.blank?

    errors.add(:start_date, "は星座の開始日以降の日付にしてください") if start_date.present? && milestone.start_date > start_date
  end

  def milestone_end_date_check
    return unless milestone
    return if milestone.is_on_chart == false

    errors.add(:end_date, "または開始日のいずれかを設定してください。チャートに表示される星座のタスクには日付が必要です") if start_date.blank? && end_date.blank?

    errors.add(:end_date, "は星座の終了日以前の日付にしてください") if end_date.present? && milestone.end_date < end_date
  end
end
