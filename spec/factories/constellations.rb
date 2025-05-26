FactoryBot.define do
  factory :constellation do
    name { Faker::Space.constellation }
    number_of_stars { Faker::Number.between(from: 3, to: 20) }
  end
end
