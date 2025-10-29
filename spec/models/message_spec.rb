require 'rails_helper'

RSpec.describe Message, type: :model do
  describe 'associations' do
    it { should belong_to(:chat) }
  end

  describe 'validations' do
    it { should validate_presence_of(:number) }
    it { should validate_presence_of(:body) }
    it { should validate_numericality_of(:number).only_integer.is_greater_than(0) }
    
    it 'validates uniqueness of number scoped to chat' do
      chat = create(:chat)
      create(:message, chat: chat, number: 1)
      duplicate = build(:message, chat: chat, number: 1)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:number]).to include('has already been taken')
    end

    it 'allows same number for different chats' do
      chat1 = create(:chat)
      chat2 = create(:chat)
      message1 = create(:message, chat: chat1, number: 1)
      message2 = build(:message, chat: chat2, number: 1)
      expect(message2).to be_valid
    end
  end
end

