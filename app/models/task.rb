class Task < ApplicationRecord
  belongs_to :milestone, optional: true
  validates :title, presence: true
end
