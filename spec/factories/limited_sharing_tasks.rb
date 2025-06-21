FactoryBot.define do
  factory :limited_sharing_task do
    id { Faker::Alphanumeric.alphanumeric(number: 21) }
    title { Faker::Lorem.sentence(word_count: 3) }
    description { Faker::Lorem.paragraph }
    progress { Faker::Number.between(from: 0, to: 2) }
    start_date { Faker::Date.between(from: 1.year.ago, to: Date.today) }
    end_date { Faker::Date.between(from: Date.today, to: 1.year.from_now) }
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
  end
end
