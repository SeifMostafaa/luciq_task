require 'rails_helper'

RSpec.describe MessagesController, type: :controller do
  let(:application) { create(:application) }
  let(:chat) { create(:chat, application: application, number: 1) }

  describe 'POST #create' do
    it 'returns accepted status' do
      post :create, params: { 
        application_token: application.token, 
        chat_number: chat.number, 
        message: { body: 'Test message' } 
      }
      expect(response).to have_http_status(:accepted)
    end

    it 'returns job_id and number' do
      post :create, params: { 
        application_token: application.token, 
        chat_number: chat.number, 
        message: { body: 'Test message' } 
      }
      json = JSON.parse(response.body)
      expect(json['job_id']).to be_present
      expect(json['number']).to eq(1)
    end

    it 'increments Redis counter' do
      key = "chat:#{application.token}:#{chat.number}:msg_seq"
      expect {
        post :create, params: { 
          application_token: application.token, 
          chat_number: chat.number, 
          message: { body: 'Test message' } 
        }
      }.to change { $redis.get(key).to_i }.from(0).to(1)
    end

    it 'enqueues MessageCreationJob' do
      expect {
        post :create, params: { 
          application_token: application.token, 
          chat_number: chat.number, 
          message: { body: 'Test message' } 
        }
      }.to change { MessageCreationJob.jobs.size }.by(1)
    end
  end

  describe 'GET #index' do
    before do
      create(:message, chat: chat, number: 1, body: 'First')
      create(:message, chat: chat, number: 2, body: 'Second')
    end

    it 'returns all messages for the chat' do
      get :index, params: { application_token: application.token, chat_number: chat.number }
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json.length).to eq(2)
    end

    it 'returns messages in order by number' do
      get :index, params: { application_token: application.token, chat_number: chat.number }
      json = JSON.parse(response.body)
      expect(json[0]['number']).to eq(1)
      expect(json[1]['number']).to eq(2)
    end
  end

  describe 'GET #show' do
    let(:message) { create(:message, chat: chat, number: 1) }

    it 'returns the message' do
      get :show, params: { 
        application_token: application.token, 
        chat_number: chat.number, 
        number: message.number 
      }
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['number']).to eq(message.number)
      expect(json['body']).to eq(message.body)
    end
  end

  describe 'PATCH #update' do
    let(:message) { create(:message, chat: chat, number: 1, body: 'Original') }

    it 'updates the message body' do
      patch :update, params: { 
        application_token: application.token, 
        chat_number: chat.number, 
        number: message.number,
        message: { body: 'Updated' }
      }
      expect(message.reload.body).to eq('Updated')
    end

    it 'returns ok status' do
      patch :update, params: { 
        application_token: application.token, 
        chat_number: chat.number, 
        number: message.number,
        message: { body: 'Updated' }
      }
      expect(response).to have_http_status(:ok)
    end
  end
end

