FactoryBot.define do
  factory :constellation do
    name { "アンドロメダ座" }
    number_of_stars { 20 }

    trait :with_few_stars do
      number_of_stars { 5 }
    end

    trait :with_many_stars do
      number_of_stars { 25 }
    end
  end
end
