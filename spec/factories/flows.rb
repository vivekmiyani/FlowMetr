FactoryBot.define do
  factory :flow do
    sequence(:name) { |n| "Flow #{n}" }
    webhook_token { SecureRandom.hex(10) }
    user
  end
end
