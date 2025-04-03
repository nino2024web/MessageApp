Rails.application.routes.draw do
  post 'users/search', to: 'users#search', as: :search_users
  post 'friends/:friend_id/open_chat', to: 'friendships#open_chat', as: :open_chat_with_friend

  devise_for :users, controllers: {
    registrations: 'users/registrations',
    sessions: 'users/sessions'
  }

  resources :users, only: [:show] do
    member do
      post 'start_chat'
    end
  end

  resources :chats, only: %i[index show]
  resources :messages, only: [:create]
  resources :friends, only: [:index]
  resources :friend_requests, only: %i[create update]
end
