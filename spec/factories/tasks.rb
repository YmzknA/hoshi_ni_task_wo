FactoryBot.define do
  factory :task do
    title { Faker::Lorem.sentence(word_count: 3) }
    description { Faker::Lorem.paragraph(sentence_count: 2) }
    progress { Faker::Number.between(from: 0, to: 2) }
    start_date { Faker::Date.between(from: 1.year.ago, to: Date.today) }
    end_date { Faker::Date.between(from: Date.today, to: 1.year.from_now) }
    association :user
    association :milestone, factory: :milestone, optional: true

    trait :with_milestone do
      association :milestone
    end

    trait :without_milestone do
      milestone { nil }
    end
  end
end
