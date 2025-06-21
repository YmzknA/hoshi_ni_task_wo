class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: [:line]

  validates :name, presence: true, length: { maximum: 20 }
  validates :bio, length: { maximum: 200 }
  validates :email, presence: true, uniqueness: { case_sensitive: false }
  validates :password, presence: true, length: { minimum: 6 }, if: :password_required?
  # providerが空でない場合はuidの一意性を検証する
  validates :uid, uniqueness: { scope: :provider }, if: :uid_required?

  has_many :tasks, dependent: :destroy
  has_many :milestones, dependent: :destroy
  has_many :limited_sharing_milestones, dependent: :destroy
  has_many :limited_sharing_tasks, dependent: :destroy

  scope :notifications_enabled, -> { where(is_notifications_enabled: true) }

  # ゲストユーザー
  def self.guest
    create do |user|
      user.email = "guest_#{SecureRandom.urlsafe_base64}@example.com"
      user.password = "password"
      user.name = "ゲストユーザー"
      user.is_guest = true
      user.bio = <<~BIO
        ゲストユーザーです。
        星座やタスクの作成や編集、削除は出来ませんが、一部の機能を体験できます。
        ぜひ、アカウントを作成して、全ての機能を体験してみてください！
      BIO
    end
  end

  def guest?
    is_guest == true
  end

  def notifications_enabled?
    is_notifications_enabled == true
  end

  def uid_required?
    provider.present?
  end

  def completed_tasks_hidden?
    is_hide_completed_tasks == true
  end
end
