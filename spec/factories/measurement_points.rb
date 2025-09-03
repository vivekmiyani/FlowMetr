FactoryBot.define do
  factory :measurement_point do
    flow
    sequence(:node_id) { |n| "node_#{n}" }
    node_type { 'checkpoint' } # Standardwert, kann überschrieben werden
    name { "Checkpoint #{node_id}" }
  end
end
