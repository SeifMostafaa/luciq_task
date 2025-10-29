require 'rails_helper'

RSpec.describe MessageCreationJob, type: :job do
  let(:chat) { create(:chat) }

  describe '#perform' do
    it 'creates a message with the specified number and body' do
      expect {
        MessageCreationJob.new.perform(chat.id, 'Test message', 1)
      }.to change(Message, :count).by(1)
      
      message = Message.last
      expect(message.number).to eq(1)
      expect(message.body).to eq('Test message')
      expect(message.chat).to eq(chat)
    end

    it 'increments chat messages_count' do
      expect {
        MessageCreationJob.new.perform(chat.id, 'Test message', 1)
      }.to change { chat.reload.messages_count }.by(1)
    end

    it 'is idempotent - does not create duplicate if called twice' do
      MessageCreationJob.new.perform(chat.id, 'Test message', 1)
      
      expect {
        MessageCreationJob.new.perform(chat.id, 'Test message', 1)
      }.not_to change(Message, :count)
    end

    it 'handles missing chat gracefully' do
      expect {
        MessageCreationJob.new.perform(999999, 'Test', 1)
      }.not_to raise_error
    end

    it 'returns the message number' do
      result = MessageCreationJob.new.perform(chat.id, 'Test message', 1)
      expect(result).to eq(1)
    end

    it 'handles Elasticsearch errors gracefully' do
      allow_any_instance_of(Message).to receive(:reindex).and_raise(Searchkick::ImportError.new('ES down'))
      
      expect {
        MessageCreationJob.new.perform(chat.id, 'Test', 1)
      }.not_to raise_error
      
      expect(Message.count).to eq(1)
    end
  end
end

