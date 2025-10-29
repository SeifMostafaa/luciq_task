require 'rails_helper'

RSpec.describe CountUpdateJob, type: :job do
  describe '#perform' do
    it 'updates application chats_count to match actual count' do
      app = create(:application, chats_count: 5)
      create_list(:chat, 3, application: app)
      
      CountUpdateJob.new.perform
      
      expect(app.reload.chats_count).to eq(3)
    end

    it 'updates chat messages_count to match actual count' do
      chat = create(:chat, messages_count: 10)
      create_list(:message, 4, chat: chat)
      
      CountUpdateJob.new.perform
      
      expect(chat.reload.messages_count).to eq(4)
    end

    it 'does not update counts if already correct' do
      app = create(:application, chats_count: 2)
      create_list(:chat, 2, application: app)
      
      expect(app).not_to receive(:update_column)
      
      CountUpdateJob.new.perform
    end

    it 'handles multiple applications and chats' do
      app1 = create(:application, chats_count: 0)
      app2 = create(:application, chats_count: 0)
      chat1 = create(:chat, application: app1, messages_count: 0)
      chat2 = create(:chat, application: app2, messages_count: 0)
      
      create(:message, chat: chat1)
      create_list(:message, 2, chat: chat2)
      
      CountUpdateJob.new.perform
      
      expect(app1.reload.chats_count).to eq(1)
      expect(app2.reload.chats_count).to eq(1)
      expect(chat1.reload.messages_count).to eq(1)
      expect(chat2.reload.messages_count).to eq(2)
    end
  end
end

