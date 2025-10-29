class Application < ApplicationRecord
  has_many :chats, dependent: :destroy

  validates :name, presence: true
  validates :token, presence: true, uniqueness: true

  before_validation :generate_token, on: :create

  # Prevent token from being changed after creation
  attr_readonly :token

  def generate_token
    self.token ||= SecureRandom.hex(16)
  end

  def self.find_by_token!(token)
    find_by!(token: token)
  end
end
