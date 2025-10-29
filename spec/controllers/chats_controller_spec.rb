require 'rails_helper'

RSpec.describe ChatsController, type: :controller do
  let(:application) { create(:application) }

  describe 'POST #create' do
    it 'returns accepted status' do
      post :create, params: { application_token: application.token }
      expect(response).to have_http_status(:accepted)
    end

    it 'returns job_id and number' do
      post :create, params: { application_token: application.token }
      json = JSON.parse(response.body)
      expect(json['job_id']).to be_present
      expect(json['number']).to eq(1)
    end

    it 'increments Redis counter' do
      expect {
        post :create, params: { application_token: application.token }
      }.to change { $redis.get("application:#{application.token}:chat_seq").to_i }.from(0).to(1)
    end

    it 'enqueues ChatCreationJob' do
      expect {
        post :create, params: { application_token: application.token }
      }.to change { ChatCreationJob.jobs.size }.by(1)
    end

    it 'allocates sequential numbers' do
      post :create, params: { application_token: application.token }
      json1 = JSON.parse(response.body)
      
      post :create, params: { application_token: application.token }
      json2 = JSON.parse(response.body)
      
      expect(json2['number']).to eq(json1['number'] + 1)
    end
  end

  describe 'GET #index' do
    before do
      create(:chat, application: application, number: 1)
      create(:chat, application: application, number: 2)
    end

    it 'returns all chats for the application' do
      get :index, params: { application_token: application.token }
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json.length).to eq(2)
    end

    it 'returns chats in order by number' do
      get :index, params: { application_token: application.token }
      json = JSON.parse(response.body)
      expect(json[0]['number']).to eq(1)
      expect(json[1]['number']).to eq(2)
    end
  end

  describe 'GET #show' do
    let(:chat) { create(:chat, application: application, number: 1) }

    it 'returns the chat' do
      get :show, params: { application_token: application.token, number: chat.number }
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['number']).to eq(chat.number)
    end

    it 'returns not found for invalid number' do
      get :show, params: { application_token: application.token, number: 999 }
      expect(response).to have_http_status(:not_found)
    end
  end
end

