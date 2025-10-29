FactoryBot.define do
  factory :chat do
    association :application
    sequence(:number) { |n| n }
    messages_count { 0 }
  end
end

