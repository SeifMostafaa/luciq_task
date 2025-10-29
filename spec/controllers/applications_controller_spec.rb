require 'rails_helper'

RSpec.describe ApplicationsController, type: :controller do
  describe 'POST #create' do
    context 'with valid parameters' do
      it 'creates a new application' do
        expect {
          post :create, params: { application: { name: 'Test App' } }
        }.to change(Application, :count).by(1)
      end

      it 'returns created status' do
        post :create, params: { application: { name: 'Test App' } }
        expect(response).to have_http_status(:created)
      end

      it 'returns token and name' do
        post :create, params: { application: { name: 'Test App' } }
        json = JSON.parse(response.body)
        expect(json['token']).to be_present
        expect(json['name']).to eq('Test App')
      end
    end

    context 'with invalid parameters' do
      it 'returns unprocessable entity status' do
        post :create, params: { application: { name: '' } }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns error messages' do
        post :create, params: { application: { name: '' } }
        json = JSON.parse(response.body)
        expect(json['errors']).to be_present
      end
    end
  end

  describe 'GET #show' do
    let(:application) { create(:application) }

    it 'returns the application' do
      get :show, params: { token: application.token }
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['token']).to eq(application.token)
      expect(json['name']).to eq(application.name)
    end

    it 'returns not found for invalid token' do
      get :show, params: { token: 'invalid_token' }
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'PATCH #update' do
    let(:application) { create(:application, name: 'Old Name') }

    context 'with valid parameters' do
      it 'updates the application name' do
        patch :update, params: { token: application.token, application: { name: 'New Name' } }
        expect(application.reload.name).to eq('New Name')
      end

      it 'does not change the token' do
        original_token = application.token
        patch :update, params: { token: application.token, application: { name: 'New Name' } }
        expect(application.reload.token).to eq(original_token)
      end

      it 'returns ok status' do
        patch :update, params: { token: application.token, application: { name: 'New Name' } }
        expect(response).to have_http_status(:ok)
      end
    end

    context 'with invalid parameters' do
      it 'returns unprocessable entity status' do
        patch :update, params: { token: application.token, application: { name: '' } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end

