require 'rails_helper'

RSpec.describe Chat, type: :model do
  describe 'associations' do
    it { should belong_to(:application) }
    it { should have_many(:messages).dependent(:destroy) }
  end

  describe 'validations' do
    it { should validate_presence_of(:number) }
    it { should validate_presence_of(:application_id) }
    it { should validate_numericality_of(:number).only_integer.is_greater_than(0) }
    
    it 'validates uniqueness of number scoped to application' do
      app = create(:application)
      create(:chat, application: app, number: 1)
      duplicate = build(:chat, application: app, number: 1)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:number]).to include('has already been taken')
    end

    it 'allows same number for different applications' do
      app1 = create(:application)
      app2 = create(:application)
      chat1 = create(:chat, application: app1, number: 1)
      chat2 = build(:chat, application: app2, number: 1)
      expect(chat2).to be_valid
    end
  end
end

