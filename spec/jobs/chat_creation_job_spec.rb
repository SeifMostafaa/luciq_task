require 'rails_helper'

RSpec.describe ChatCreationJob, type: :job do
  let(:application) { create(:application) }

  describe '#perform' do
    it 'creates a chat with the specified number' do
      expect {
        ChatCreationJob.new.perform(application.id, 1)
      }.to change(Chat, :count).by(1)
      
      chat = Chat.last
      expect(chat.number).to eq(1)
      expect(chat.application).to eq(application)
    end

    it 'increments application chats_count' do
      expect {
        ChatCreationJob.new.perform(application.id, 1)
      }.to change { application.reload.chats_count }.by(1)
    end

    it 'is idempotent - does not create duplicate if called twice' do
      ChatCreationJob.new.perform(application.id, 1)
      
      expect {
        ChatCreationJob.new.perform(application.id, 1)
      }.not_to change(Chat, :count)
    end

    it 'handles missing application gracefully' do
      expect {
        ChatCreationJob.new.perform(999999, 1)
      }.not_to raise_error
    end

    it 'returns the chat number' do
      result = ChatCreationJob.new.perform(application.id, 1)
      expect(result).to eq(1)
    end
  end
end

