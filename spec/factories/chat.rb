FactoryBot.define do
  factory :chat do
    association :listener
    association :room
    message { Faker::Lorem.characters(number: 50) }
  end
end
