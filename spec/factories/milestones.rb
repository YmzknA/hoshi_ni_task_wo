FactoryBot.define do
  factory :milestone do
    title { Faker::Lorem.sentence(word_count: 3) }
    description { Faker::Lorem.paragraph }
    progress { Faker::Number.between(from: 0, to: 2) }
    is_public { Faker::Boolean.boolean }
    is_on_chart { Faker::Boolean.boolean }
    is_open { Faker::Boolean.boolean }
    start_date { Faker::Date.between(from: 1.year.ago, to: Date.today) }
    end_date { Faker::Date.between(from: Date.today, to: 1.year.from_now) }
    # progressが2の場合はcompleted commentが必須
    completed_comment { Faker::Lorem.sentence(word_count: 5) if progress == 2 }
    color { "#FFDF5E" }
    association :user, factory: :user

    trait :completed do
      progress { 2 }
      completed_comment { Faker::Lorem.sentence(word_count: 5) }
    end

    trait :with_tasks do
      transient do
        tasks_count { 5 }
      end

      after(:create) do |milestone, evaluator|
        create_list(:task, evaluator.tasks_count, milestone: milestone)
      end
    end
  end
end
