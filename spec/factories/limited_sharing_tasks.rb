FactoryBot.define do
  factory :limited_sharing_task do
    id { Faker::Alphanumeric.alphanumeric(number: 21) }
    title { Faker::Lorem.sentence(word_count: 3) }
    description { Faker::Lorem.paragraph }
    progress { Faker::Number.between(from: 0, to: 2) }
    start_date { Faker::Date.between(from: 1.year.ago, to: Date.today) }
    end_date { start_date + rand(1..365).days }
    association :user

    # limited_sharing_milestone_idをセットするために必要な関連付け
    transient do
      create_milestone { true }
    end

    before(:create) do |limited_sharing_task, evaluator|
      if evaluator.create_milestone
        limited_sharing_task.limited_sharing_milestone_id = create(:limited_sharing_milestone).id
      end
    end

    trait :not_started do
      progress { :not_started }
    end

    trait :in_progress do
      progress { :in_progress }
    end

    trait :completed do
      progress { :completed }
    end

    trait :no_dates do
      start_date { nil }
      end_date { nil }
    end
  end
end
