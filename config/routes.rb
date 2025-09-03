require 'sidekiq/web'

Rails.application.routes.draw do
  get "/subscription/success", to: "subscriptions#success", as: :subscription_success
  
  namespace :public do
    get 'projects/:public_token', to: 'projects#show', as: :public_project
  end
  
  get "welcome/show"
  get "projects/index"
  get "projects/show"
  get "projects/new"
  get "projects/create"
  get "projects/edit"
  get "projects/update"
  get "projects/destroy"

  get "/welcome", to: "welcome#show", as: :welcome

  root to: "pages#home"

  devise_for :users, controllers: { 
    invitations: 'users/invitations',
    registrations: 'users/registrations',
    sessions: 'users/sessions'
  }

  authenticate :user, lambda { |u| u.admin? } do
    mount Motor::Admin => '/motor_admin'
    mount Sidekiq::Web => '/sidekiq'
  end

  get "/runs", to: "runs#index", as: :runs
  get "/runs/:id", to: "runs#show", as: :run
  get "/dashboard", to: "dashboard#show", as: :dashboard
  get 'hooks/:token', to: 'webhooks#receive', as: :webhook_receiver

  resources :flows do
    member do
      get :settings
      get :download_template
    end

    resources :measurement_points, only: [:create]
  end

  resources :projects do
    resources :flows, only: [:index] # Optional: to list flows by project
    member do
      post :generate_public_token
      post :regenerate_public_token
      post :regenerate_secret_token
      post :disable_public_token
    end
  end
  resources :measurement_points, only: [:create, :destroy]

  # Static pages
  get "/checkout", to: "checkout#create", as: :checkout
  get 'terms', to: 'pages#terms'
  get 'privacy', to: 'pages#privacy'
  get 'imprint', to: 'pages#imprint'
  get 'about', to: 'pages#about'
end
