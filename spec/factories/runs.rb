FactoryBot.define do
  factory :run do
    flow
    uuid { SecureRandom.uuid }
    status { :pending }
    started_at { 1.hour.ago }

    trait :pending do
      status { :pending }
    end

    trait :completed do
      status { :successful }
      ended_at { Time.current }
      duration { 3600 } # 1 hour in seconds
    end

    trait :failed do
      status { :failed }
      error { true }
      ended_at { Time.current }
      duration { 1800 } # 30 minutes in seconds
    end
  end
end
