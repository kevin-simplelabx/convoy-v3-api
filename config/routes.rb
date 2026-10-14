Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check
  get "config.js", to: "config#show"

  devise_for :users, skip: :all

  namespace :api do
    # OSRM proxy — no auth, cached in memory
    # format: false prevents Rails from stripping .3000 (decimal coords) as a file extension
    get "osrm/*path", to: "osrm#proxy", format: false

    namespace :v1 do
      get    "health",   to: "health#show"
      get    "session",  to: "sessions#show"
      post   "login",    to: "sessions#create"
      post   "login-as", to: "sessions#demo"
      delete "logout",   to: "sessions#destroy"
      post   "context",  to: "sessions#update_context"

      get  "companies",    to: "companies#index"
      post "companies",    to: "companies#create"
      put  "company/logo", to: "companies#update_logo"

      get  "users",     to: "users#index"
      post "users",     to: "users#create"
      put  "users/:id", to: "users#update"

      # Schools
      get  "schools",     to: "schools#index"
      post "schools",     to: "schools#create"

      # Datasets (nested under school)
      get    "schools/:school_id/datasets",  to: "datasets#index"
      post   "schools/:school_id/datasets",  to: "datasets#create"
      delete "datasets/:id",                 to: "datasets#destroy"

      # Riders
      get  "schools/:school_id/riders",       to: "riders#index"
      post "schools/:school_id/riders",       to: "riders#create"
      get  "schools/:school_id/rider-events", to: "riders#events"
      get  "schools/:school_id/labels",       to: "riders#labels"
      put  "schools/:school_id/labels",       to: "riders#update_labels"

      # Stop library
      get "stops", to: "stops#show"
      put "stops", to: "stops#update"

      # Library approval
      get  "library/requests",       to: "library#requests"
      post "library/:uid/status",    to: "library#update_status"

      # Plans & Drafts
      get "schools/:school_id/plans", to: "plans#show"
      put "schools/:school_id/plans", to: "plans#update"
      get "schools/:school_id/draft", to: "plans#show_draft"
      put "schools/:school_id/draft", to: "plans#update_draft"

      # Routing solver proxy
      post "solve", to: "solve#create"

      # Vehicles & Attendants
      get    "vehicles",     to: "vehicles#index"
      post   "vehicles",     to: "vehicles#create"
      delete "vehicles/:id", to: "vehicles#destroy"

      get    "attendants",     to: "attendants#index"
      post   "attendants",     to: "attendants#create"
      delete "attendants/:id", to: "attendants#destroy"

      # Trips
      get    "trips",      to: "trips#index"
      post   "trips",      to: "trips#create"
      delete "trips/:id",  to: "trips#destroy"

      # Company settings (calendar, fares, pay schemes, etc. — NOT trips)
      get "settings", to: "settings#show"
      put "settings", to: "settings#update"
    end
  end
end
