FactoryBot.define do
  factory :limited_sharing_milestone do
    id { Faker::Alphanumeric.alphanumeric(number: 21) }
    title { Faker::Lorem.sentence(word_count: 3) }
    description { Faker::Lorem.paragraph }
    progress { Faker::Number.between(from: 0, to: 1) }
    color { "#FFDF5E" }
    start_date { Faker::Date.between(from: 1.year.ago, to: Date.today) }
    end_date { start_date + rand(1..365).days }
    completed_comment { Faker::Lorem.sentence(word_count: 5) }
    is_on_chart { false }
    association :user

    trait :completed do
      progress { 2 } # completed
      completed_comment { Faker::Lorem.sentence(word_count: 5) }
    end

    trait :with_tasks do
      transient do
        tasks_count { 3 }
      end

      after(:create) do |milestone, evaluator|
        create_list(:limited_sharing_task, evaluator.tasks_count,
                    limited_sharing_milestone_id: milestone.id,
                    user: milestone.user,
                    create_milestone: false)
      end
    end
  end
end
