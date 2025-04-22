Rails.application.routes.draw do
  resources :tasks do
    patch "update_progress", on: :member
  end

  resources :milestones do
    get "show_complete_page", on: :member
    patch "complete", on: :member
  end

  devise_for :users, controllers: {
    registrations: "users/registrations",
    sessions: "users/sessions",
    omniauth_callbacks: "users/omniauth_callbacks"
  }

  root "static_pages#home"
  get "user_check" => "static_pages#user_check"
  get "privacy_policy" => "static_pages#privacy_policy"
  get "terms_of_service" => "static_pages#terms_of_service"

  resources :users, only: [:show]

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/*
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  # Defines the root path route ("/")
  # root "posts#index"
end
