FactoryBot.define do
  factory :message do
    association :chat
    sequence(:number) { |n| n }
    body { Faker::Lorem.sentence }
  end
end

