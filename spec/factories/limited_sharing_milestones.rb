FactoryBot.define do
  factory :limited_sharing_milestone do
    id { Faker::Alphanumeric.alphanumeric(number: 21) }
    title { Faker::Lorem.sentence(word_count: 3) }
    description { Faker::Lorem.paragraph }
    progress { Faker::Number.between(from: 0, to: 2) }
    color { "#FFDF5E" }
    start_date { Faker::Date.between(from: 1.year.ago, to: Date.today) }
    end_date { Faker::Date.between(from: Date.today, to: 1.year.from_now) }
    completed_comment { Faker::Lorem.sentence(word_count: 5) if progress == 2 }
    is_on_chart { false }
    association :user
    association :constellation, factory: :constellation, optional: true
  end
end
