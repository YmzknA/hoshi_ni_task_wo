Rails.application.routes.draw do
  get "images/ogp.png", to: "images#ogp", as: "images_ogp"

  resources :tasks, only: [:index, :create, :edit, :update, :destroy] do
    collection do
      get :autocomplete
    end
  end
  namespace :tasks do
    resources :copies, only: [:show, :create]
    patch "update_progress/:id", to: "update_progress#update", as: :update_progress
  end

  resources :milestones do
    get "show_complete_page", on: :member
    patch "complete", on: :member
    get "share" => "limited_sharing_milestones#show", on: :member

    collection do
      get :autocomplete
    end
  end
  namespace :milestones do
    resources :copies, only: [:show, :create]
  end

  resources :limited_sharing_milestones, only: [:create, :destroy]

  resources :task_milestone_assignments, only: [:show, :update]

  get "gantt_chart" => "gantt_chart#show", as: :gantt_chart
  get "gantt_chart_milestone/:id" => "gantt_chart#milestone_show", as: :gantt_chart_milestone_show

  patch "milestone_open_toggle/:id" => "milestone_open_toggle#toggle", as: :milestone_open_toggle

  post "callback" => "line_bot#callback"

  devise_for :users, controllers: {
    registrations: "users/registrations",
    sessions: "users/sessions",
    omniauth_callbacks: "users/omniauth_callbacks"
  }

  devise_scope :user do
    post "users/guest_sign_in" => "users/registrations#guest_sign_in"
  end

  root "static_pages#home"
  get "user_check" => "static_pages#user_check"
  get "privacy_policy" => "static_pages#privacy_policy"
  get "terms_of_service" => "static_pages#terms_of_service"

  resources :users, only: [:show] do
    member do
      patch "toggle_notifications" => "users#toggle_notifications"
      patch "toggle_hide_completed_tasks" => "users#toggle_hide_completed_tasks"
    end
  end

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
