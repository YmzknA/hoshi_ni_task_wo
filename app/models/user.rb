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
end
