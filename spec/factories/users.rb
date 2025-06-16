FactoryBot.define do
  factory :user do
    name { Faker::Name.name }
    email { Faker::Internet.email }
    password { "password" }
    password_confirmation { "password" }
    bio { Faker::Lorem.paragraph }
    is_guest { false }
    is_notifications_enabled { false }
    provider { nil }
    uid { nil }

    trait :guest do
      is_guest { true }
    end

    trait :with_notifications do
      is_notifications_enabled { true }
    end

    trait :with_oauth do
      provider { "line" }
      uid { 123456789 }
    end
  end
end
