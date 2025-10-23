FactoryBot.define do
  factory :task do
    title { Faker::Lorem.sentence(word_count: 3) }
    description { Faker::Lorem.paragraph(sentence_count: 2) }
    progress { :not_started }
    start_date { Date.today }
    end_date { Date.today + 7.days }
    association :user
    milestone { nil }

    trait :with_milestone do
      association :milestone
    end

    trait :without_milestone do
      milestone { nil }
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

    trait :start_date_only do
      start_date { Date.today }
      end_date { nil }
    end

    trait :end_date_only do
      start_date { nil }
      end_date { Date.today + 7.days }
    end

    trait :invalid_date_range do
      start_date { Date.today + 7.days }
      end_date { Date.today }
    end

    trait :with_chart_milestone do
      association :milestone, :on_chart
    end

    trait :long_title do
      title { "a" * 26 }
    end

    trait :long_description do
      description { "a" * 151 }
    end
  end
end
