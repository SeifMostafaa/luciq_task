require 'rails_helper'

RSpec.describe Application, type: :model do
  describe 'associations' do
    it { should have_many(:chats).dependent(:destroy) }
  end

  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:token) }
    
    it 'validates uniqueness of token' do
      create(:application, token: 'unique_token')
      duplicate = build(:application, token: 'unique_token')
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:token]).to include('has already been taken')
    end
  end

  describe 'token generation' do
    it 'generates a token before validation on create' do
      app = Application.new(name: 'Test App')
      expect(app.token).to be_nil
      app.valid?
      expect(app.token).to be_present
      expect(app.token.length).to eq(32) # 16 bytes = 32 hex chars
    end

    it 'does not override existing token' do
      app = Application.new(name: 'Test App', token: 'custom_token')
      app.valid?
      expect(app.token).to eq('custom_token')
    end

    it 'generates unique tokens for multiple applications' do
      app1 = create(:application)
      app2 = create(:application)
      expect(app1.token).not_to eq(app2.token)
    end
  end

  describe 'token immutability' do
    it 'prevents token from being changed after creation' do
      app = create(:application)
      original_token = app.token
      app.update(token: 'new_token')
      expect(app.reload.token).to eq(original_token)
    end
  end

  describe '.find_by_token!' do
    it 'finds application by token' do
      app = create(:application)
      found = Application.find_by_token!(app.token)
      expect(found).to eq(app)
    end

    it 'raises error when token not found' do
      expect { Application.find_by_token!('nonexistent') }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end

