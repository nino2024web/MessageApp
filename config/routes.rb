Rails.application.routes.draw do
  post 'users/search', to: 'users#search', as: :search_users

  devise_for :users, controllers: {
    registrations: 'users/registrations',
    sessions: 'users/sessions'
  }

  resources :users, only: [:show]
  resources :chats, only: %i[index show]
  resources :friends, only: [:index]
  resources :friend_requests, only: %i[create update]
end
