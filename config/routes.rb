Rails.application.routes.draw do
  root 'home#index'

  devise_for :users, controllers: {
    registrations: 'users/registrations',
    sessions: 'users/sessions'
  }

  resources :users, only: [:show]

  resources :conversations, only: %i[index show new create] do
    resources :messages, only: [:create]
  end

  resources :friends do
    collection do
      post :search
    end
  end
end
