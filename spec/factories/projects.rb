FactoryBot.define do
  factory :project do
    sequence(:name) { |n| "Project #{n}" }
    user
    
    # These callbacks will be handled by the model:
    # - generate_public_token
    # - generate_secret_token
  end
end
