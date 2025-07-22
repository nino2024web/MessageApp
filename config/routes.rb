Rails.application.routes.draw do
  scope :personal do
    resources :users, only: [:show], controller: 'users/personal', as: :personal_user
  end

  scope :group do
    resources :users, only: [:show], controller: 'users/group', as: :group_user
  end

  post 'users/search', to: 'users#search', as: :search_users
  post 'friends/:friend_id/open_chat', to: 'friendships#open_chat', as: :open_chat_with_friend
  post 'chat_rooms/:id/invite', to: 'chat_rooms#invite', as: :invite_to_chat_room
  post 'start_chat/:id', to: 'users#start_chat', as: :start_chat_user
  post 'messages/:id/mark_as_read', to: 'messages#mark_as_read'
  post 'group_chats/broadcast_updated_chat_item', to: 'group_chats#broadcast_updated_chat_item'

  devise_for :users, controllers: {
    registrations: 'users/registrations',
    sessions: 'users/sessions'
  }

  root to: 'users#show'

  resources :group_messages do
    collection do
      post :mark_as_read
    end
  end

  resources :messages, only: [:create]
  resources :friendships, only: [:index]
  resources :friend_requests, only: %i[create update index]
  resources :blocks, only: %i[create destroy]
  resources :chat_rooms, only: %i[new create]
  resources :group_messages, only: [:create]
end
