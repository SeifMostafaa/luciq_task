class Chat < ApplicationRecord
  belongs_to :application
  has_many :messages, dependent: :destroy

  validates :number, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :application_id, presence: true
  validates :number, uniqueness: { scope: :application_id }
end
