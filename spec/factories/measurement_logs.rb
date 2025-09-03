FactoryBot.define do
  factory :measurement_log do
    run
    measurement_point
    received_at { Time.current }
    logs { { "key" => "value" } }
  end
end
