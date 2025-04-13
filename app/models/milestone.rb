class Milestone < ApplicationRecord
  has_many :tasks
  belongs_to :user

  validates :title, presence: true
  validates :start_date, presence: true, if: -> { should_validate_dates? }
  validates :end_date, presence: true, if: -> { should_validate_dates? && progress > 0 }

  private

  def should_validate_dates?
    # 特定の条件下でのみバリデーションを行うロジック
    # 例: 公開されているマイルストーンや進行中のマイルストーンには日付が必要
    is_public || progress > 0
  end
end
