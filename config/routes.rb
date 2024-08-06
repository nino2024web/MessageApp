Rails.application.routes.draw do
  get 'home/index'
  root "home#index"

  devise_for :users

  resources :conversations, only: [:index, :show, :new, :create] do
    resources :messages, only: [:create]
  end
end
