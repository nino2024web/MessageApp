Rails.application.routes.draw do
  root "home#index"

  devise_for :users, controllers: {
    registrations: "users/registrations",
    sessions: 'users/sessions'
  }

  resources :conversations, only: [:index, :show, :new, :create] do
    resources :messages, only: [:create]
  end

  resources :friends
end
