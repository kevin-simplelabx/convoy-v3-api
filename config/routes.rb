Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  devise_for :users, skip: :all
  devise_for :portal_accounts, skip: :all

  namespace :api, defaults: { format: :json } do
    namespace :v1 do
      resource :session, only: %i[show create update destroy]

      # Client Portal sign-in (people at Managed Clients)
      namespace :portal do
        resource :session, only: %i[show create update destroy] do
          post :lookup
          post :code
          post :verify
        end
        resource :password, only: :create
      end
      resources :companies, only: %i[index show create update]

      # HR (driver pay)
      scope "pay", as: "pay" do
        resources :rate_plans, controller: :pay_rate_plans do
          member do
            post :lock
            post :unlock
            get :coverage
          end
        end
        resources :schemes, controller: :pay_schemes do
          member do
            post :lock
            post :unlock
          end
        end
        get "earnings", to: "pay_earnings#index"
        get "earnings/:driver_id", to: "pay_earnings#show", as: :earning
        post "earnings/:driver_id/confirm", to: "pay_earnings#confirm", as: :earning_confirm
        delete "earnings/:driver_id/confirm", to: "pay_earnings#reopen"
        post "simulate", to: "pay_simulator#simulate"
        get "simulate/sample", to: "pay_simulator#sample", as: :simulate_sample
        get "simulator_templates", to: "pay_simulator#templates"
        put "simulator_templates/:slot", to: "pay_simulator#save_template", as: :simulator_template
        delete "simulator_templates/:slot", to: "pay_simulator#delete_template"
        resources :bonuses, controller: :pay_bonuses do
          get :periods, on: :collection
          member do
            post :lock
            post :unlock
          end
        end
        get "audit_log", to: "pay_audit_log#index"
        resources :rewards, controller: :pay_rewards
        get "points", to: "pay_points#index"
        get "points/:driver_id", to: "pay_points#show", as: :points_driver
        post "points/:driver_id", to: "pay_points#create"
        resources :drivers, controller: :pay_drivers, only: %i[index show] do
          member do
            post ":kind", action: :create_assignment, as: :assignments, constraints: { kind: /schemes|vehicle_types/ }
            patch ":kind/:assignment_id", action: :update_assignment, as: :assignment, constraints: { kind: /schemes|vehicle_types/ }
            delete ":kind/:assignment_id", action: :destroy_assignment, constraints: { kind: /schemes|vehicle_types/ }
          end
        end
      end

      # Settings
      resource :profile, only: %i[show update]
      resources :countries, only: :index
      resources :country_requests, only: %i[index create] do
        member do
          post :withdraw
          post :approve
          post :decline
        end
      end
      resources :users, only: %i[index show create update destroy] do
        get :roles, on: :collection
        member do
          post :suspend
          post :activate
        end
      end
      get "downloads/:token", to: "downloads#show", as: :download
      resources :document_reads, only: %i[create show]

      # Calendars
      resources :public_holidays, only: %i[index create update destroy] do
        post :import, on: :collection
      end
      resources :calendars do
        get :trips, on: :member
        resources :days, controller: :calendar_days, only: %i[create update destroy]
      end

      # Clients
      get "client_users/roles", to: "client_users#roles", as: :client_user_roles
      resources :clients do
        put :bookable_vehicle_types, on: :member
        resources :users, controller: :client_users, only: %i[index create update destroy]
        resources :sites, controller: :client_sites, only: %i[index create update destroy]
        resources :end_customers, controller: :client_end_customers, only: %i[index create update destroy]
        resources :pickup_points, controller: :client_pickup_points, only: %i[index create update destroy]
      end

      # Fleet
      resources :vehicle_types, only: %i[index create update destroy] do
        patch :toggle, on: :member
      end
      resources :vehicle_type_requests, only: %i[index create] do
        member do
          patch :approve
          patch :decline
        end
      end
      resources :vehicle_teams, only: %i[index create update destroy] do
        put :bulk, on: :collection
      end
      resources :operators
      resources :banks, only: :index do
        get :branch, on: :member
      end
      resources :vehicles do
        post :external, on: :collection, action: :create_external
        resources :driver_schedules, controller: :vehicle_driver_schedules, only: %i[index create destroy]
        resources :log_cards, controller: :vehicle_log_cards, only: %i[index create destroy] do
          patch :resolve_plate, on: :member
        end
        resources :insurance_policies, controller: :vehicle_insurance_policies, only: %i[index create update destroy] do
          post :renew, on: :collection
        end
        resources :insurance_documents, controller: :vehicle_insurance_documents, only: %i[create update destroy]
      end
      concern :invited do
        member do
          patch :resend
          patch :accept
          patch :decline
          patch :reinvite
          patch :remove
          get :details
          patch :display, action: :set_display
        end
      end
      resources :drivers, concerns: :invited
      resources :operator_drivers, concerns: :invited do
        get :assign_preview, on: :collection
        patch :assign_vehicle, on: :member
      end
      resources :attendants, only: %i[index create update destroy]

      # Fuel & Energy
      # new: the blank form (API mode leaves :new out of resources unless named)
      resources :fuel_entries, only: %i[index new show create update destroy] do
        get :vehicles, on: :collection
      end
      resources :fuel_companies, only: :index do
        put :bulk, on: :collection
      end
      resources :fuel_alerts, only: :index do
        member do
          patch :check
          patch :reopen
        end
      end
      get "fuel/kpis", to: "fuel#kpis", as: :fuel_kpis
      get "fuel/usage", to: "fuel#usage", as: :fuel_usage
      resource :external_share_link, only: :show do
        post :reset
      end
      resources :external_vehicle_submissions, only: :index do
        patch :dismiss, on: :member
      end

      # Trips
      resources :trips do
        get :prices, on: :member
        resources :attachments, controller: :trip_attachments, only: %i[create destroy]
        resources :assignments, controller: :trip_assignments, only: %i[index create destroy]
        resources :run_groups, controller: :trip_run_groups, only: %i[create destroy]
        post :route_list, to: "route_lists#apply"
        get :route_list_versions, to: "route_lists#versions"
        get :school_run_bill, to: "route_lists#bill"
        resources :stops, only: [] do
          resources :photos, controller: :trip_stop_photos, only: %i[create destroy]
        end
      end
      post "rate_cards/quote", to: "rate_cards#quote", as: :rate_card_quote

      # Bookings
      resources :bookings, only: %i[index show create update] do
        post :estimate, on: :collection
        resources :attachments, controller: :booking_attachments, only: %i[create destroy]
        resources :cancel_requests, controller: :booking_cancel_requests, only: %i[create update]
      end
      resources :booking_trips, only: [] do
        member do
          post :approve
          patch :reject
          patch :acknowledge
          patch :client_approve
          patch :client_decline
        end
      end
      resource :booking_notifications, only: :show do
        patch :seen
        get :preferences
        patch :preferences, action: :update_preferences
      end

      # Rate Cards page
      resources :rate_cards, only: %i[index show new create update] do
        post :check, on: :collection
        member do
          patch :make_default
          patch :archive
          patch :unarchive
        end
      end
      resources :rate_card_assignments, only: %i[index update], param: :client_id

      # School Run
      post "route_lists/review", to: "route_lists#review", as: :route_list_review
      resources :pickup_points, only: %i[index create update destroy]

      # Maintenance and notices
      resources :workshops, only: %i[index create update destroy]
      resources :maintenance_visits, only: %i[index new show create update] do
        get :summary, on: :collection
        patch :cancel, on: :member
      end
      resources :notices, only: %i[index show create update destroy] do
        member do
          patch :end_now
          post :duplicate
        end
      end
      resources :notice_templates, only: %i[index create update destroy]

      # Public (no sign-in): the Trip Tracking page
      namespace :public do
        get "tracking/:token", to: "tracking#show", as: :tracking
        get "share_forms/:token", to: "share_forms#show", as: :share_form
        post "share_forms/:token", to: "share_forms#create"
      end

      # Trip History
      get "trip_history", to: "trip_history#index", as: :trip_history
      get "trip_history/:id", to: "trip_history#show", as: :trip_history_run
      get "trip_history/:id/track", to: "trip_history#track", as: :trip_history_track
      post "trip_history/:id/notes", to: "trip_history#create_note", as: :trip_history_notes
      post "trip_history/:id/correction", to: "trip_history#correct", as: :trip_history_correction

      # Scheduler and runs
      resource :scheduler, only: :show, controller: :scheduler do
        get :assign_summary
      end
      resources :replacements, only: %i[index show create update destroy] do
        get :preview, on: :collection
      end
      resources :occurrences, only: %i[index show] do
        get :list, on: :collection
        member do
          patch :cancel
          patch :restore
          post :issue
          delete :issue, action: :clear_issue
          patch :time
          get :move_preview
          post :move
          patch :regular_bus
          post :tracking_link
          get :passengers
          patch "passengers/:key", action: :mark_passenger, as: :mark_passenger
        end
      end
    end
  end
end
