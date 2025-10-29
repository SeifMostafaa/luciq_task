Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Applications routes
  resources :applications, only: [:create]
  get "applications/:token", to: "applications#show", as: :application_by_token
  patch "applications/:token", to: "applications#update", as: :update_application_by_token
  put "applications/:token", to: "applications#update"

  # Chats routes (nested under applications by token)
  scope "applications/:application_token" do
    resources :chats, only: [:create, :index]
    get "chats/:number", to: "chats#show", as: :application_chat
  end

  # Messages routes (nested under applications and chats)
  scope "applications/:application_token/chats/:chat_number" do
    # Search must come before messages/:number to avoid route collision
    get "messages/search", to: "messages#search", as: :search_messages
    
    resources :messages, only: [:create, :index]
    get "messages/:number", to: "messages#show", as: :application_chat_message
    patch "messages/:number", to: "messages#update"
    put "messages/:number", to: "messages#update"
  end

  # Defines the root path route ("/")
  # root "posts#index"
end
