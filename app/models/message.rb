class Message < ApplicationRecord
  belongs_to :chat

  searchkick word_start: [:body]

  validates :number, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :number, uniqueness: { scope: :chat_id }
  validates :body, presence: true
end