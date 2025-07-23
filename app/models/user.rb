class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable, :omniauthable, omniauth_providers: [:line]

  validates :name, presence: true, length: { maximum: 20 }
  validates :bio, length: { maximum: 200 }
  validates :email, presence: true, uniqueness: { case_sensitive: false }
  # Deviseがpassword_required?メソッドを提供している
  validates :password, presence: true, length: { minimum: 6 }, if: :password_required?
  validates :notification_time, presence: true, inclusion: { in: 0..23 }
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

  def new_user?
    !tasks.exists? && !milestones.exists?
  end

  # Lineログイン用の設定
  def social_profile(provider)
    social_profiles.select { |sp| sp.provider == provider.to_s }.first
  end

  # rubocop:disable Naming/AccessorMethodName
  def set_values(omniauth)
    return if provider.to_s != omniauth["provider"].to_s || uid != omniauth["uid"]

    credentials = omniauth["credentials"]
    info = omniauth["info"]

    # rubocop:disable Lint/UselessAssignment
    access_token = credentials["refresh_token"]
    access_secret = credentials["secret"]
    credentials = credentials.to_json
    name = info["name"]
    # rubocop:enable Lint/UselessAssignment
  end

  # rubocop:disable Style/RedundantSelf
  def set_values_by_raw_info(raw_info)
    self.raw_info = raw_info.to_json
    self.save!
  end
  # rubocop:enable Naming/AccessorMethodName
  # rubocop:enable Style/RedundantSelf

  # メール認証が必要かどうかを判定
  def confirmation_required?
    # LINE認証ユーザーとゲストユーザーは認証不要
    !guest? && provider.blank?
  end

  # メール認証済みまたは認証不要なユーザーかを判定
  def confirmed_or_not_required?
    confirmed? || !confirmation_required?
  end

  # ゲストユーザーと同様の制限が必要かを判定
  def restricted_user?
    guest? || (confirmation_required? && !confirmed?)
  end
end
