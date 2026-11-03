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

      # Convoy Admin
      resources :message_terms, only: %i[index create update destroy]
      get "leads", to: "company_leads#index"
      patch "leads/:id", to: "company_leads#update", as: :lead, constraints: { id: %r{[^/]+} }
      scope "discover", controller: :discover, as: :discover do
        get :advertisers
        post :advertisers, action: :create_advertiser
        patch "advertisers/:id", action: :update_advertiser, as: :advertiser
        delete "advertisers/:id", action: :destroy_advertiser
        get :placements
        post :placements, action: :create_placement
        get "placements/:id", action: :placement, as: :placement
        patch "placements/:id", action: :update_placement
        delete "placements/:id", action: :destroy_placement
        post "placements/:id/pause", action: :pause, as: :placement_pause
        post "placements/:id/resume", action: :resume, as: :placement_resume
        post "placements/:id/end", action: :end_now, as: :placement_end
        post "placements/:id/duplicate", action: :duplicate, as: :placement_duplicate
      end

      # Dashboard
      get "dashboard", to: "dashboard#show"
      get "dashboard/widgets", to: "dashboard#widgets"
      get "dashboard/layout", to: "dashboard#layout"
      put "dashboard/layout", to: "dashboard#save_layout"
      delete "dashboard/layout", to: "dashboard#reset_layout"

      # School Bus
      resources :schools, only: %i[index show create] do
        put :route_labels, on: :member, action: :update_labels
        post :unlock, on: :member
        resource :levels, controller: :school_levels, only: %i[show update]
        resource :bus_attendants, controller: :school_attendant_policies, only: %i[show update]
        resource :policy, controller: :school_policies, only: %i[show create]
        resource :payment_methods, controller: :school_payment_methods, only: %i[show update]
        resource :operator_pay, controller: :school_operator_pays, only: %i[show update] do
          post :calculator
        end
        resources :stops, controller: :school_stops, only: %i[index update destroy] do
          post :import, on: :collection
        end
        get :stop_assignment, to: "school_stops#assignment"
        post :routing_runs, to: "routing#run"
        get :route_charges, to: "route_money#charges"
        resource :cca_rides, only: %i[show update] do
          post :not_running
        end
        resources :bus_requests, only: %i[index create] do
          collection do
            post :accept, action: :accept_many
            post :decide
            post :message
          end
        end
        resources :families, only: %i[index create], shallow: true do
          collection do
            post :import
            get :export
          end
        end
        resources :rider_assignments, only: :create do
          collection do
            post :move
            post :notify
          end
        end
        resources :plans, controller: :school_plans, only: %i[index create], shallow: true
        post :rider_links, to: "school_stops#link"
        post "rider_links/remove", to: "school_stops#unlink", as: :remove_rider_links
        resources :rider_datasets, only: %i[index create destroy] do
          post :preview, on: :collection
        end
        resources :riders, controller: :school_riders, only: %i[index create] do
          get :export, on: :collection
        end
        resources :academic_years, only: %i[index create], shallow: true
      end
      get "routing/settings", to: "routing#settings"
      put "routing/settings", to: "routing#save_settings"
      get "routing_runs/:id", to: "routing#show_run", as: :routing_run
      resources :bus_requests, only: :show do
        collection do
          get :alerts
          get :digest
        end
        member do
          post :open
          post :acknowledge
          post :move_answer
          post :accept
          post :reoffer
          post :record_payment
          post :confirm_change
          post :confirm_stop
          post :not_agreed
          post :end_rider
        end
      end
      resources :families, only: %i[show update destroy] do
        member do
          post :guardians, action: :guardian
          match "guardians/:guardian_id", action: :guardian, via: %i[patch delete], as: :guardian
          post :riders, action: :link
          delete "riders/:rid", action: :unlink, as: :rider
          get :candidates
        end
      end
      resources :feasibility_studies, only: %i[index show create update destroy] do
        get :fare_source, on: :collection
        member do
          match :rows, via: %i[post delete]
          post :scenarios, action: :add_scenario
        end
      end
      resources :feasibility_scenarios, controller: :feasibility_studies, only: [] do
        member do
          patch "/", action: :update_scenario, as: ""
          delete "/", action: :destroy_scenario
          post :run
          post :use_suggested_fares, action: :use_suggested
        end
      end
      patch "route_charges/:id", to: "route_money#update_charge", as: :route_charge
      delete "route_charges/:id", to: "route_money#remove_charge"
      resources :routes, controller: :school_routes, only: %i[update destroy] do
        member do
          put :stops, action: :update_stops
          post :reset
          post :vehicle, to: "route_money#vehicle"
          post :prices, to: "route_money#price"
          post :charges, to: "route_money#add_charge"
        end
      end
      resources :plans, controller: :school_plans, only: %i[show update destroy] do
        resources :routes, controller: :school_routes, only: :create
        post :route_again, to: "school_routes#route_again"
        member do
          post :comments, action: :comment
          delete "comments/:comment_id", action: :uncomment, as: :comment
          get :compare
          post :adopt
          post :cancel_adoption
        end
      end
      resources :stop_photo_requests, only: %i[index create destroy] do
        collection do
          put :auto
          post "submissions/:id/accept", action: :accept, as: :accept_submission
          post "submissions/:id/reject", action: :reject, as: :reject_submission
        end
      end
      resources :stops, only: %i[index show create update destroy] do
        collection do
          get :nearby
          get :requests
        end
        member do
          post :library, action: :ask_library
          post :review
          match "points/:point_id/photo", action: :photo, via: %i[post delete], as: :point_photo
        end
      end
      resources :academic_years, only: %i[show destroy] do
        resource :fares, controller: :fare_tables, only: %i[show update] do
          get :copy
        end
        resources :extra_charges, only: %i[index create update destroy] do
          post :end, on: :member, action: :end_charge
          post :preview, on: :collection
        end
        resources :sessions, controller: :bus_sessions, only: :index do
          collection do
            put "/", action: :update
            get :copy
          end
        end
        resource :registration, controller: :school_registrations, only: %i[show update] do
          post :schedule
          post :unschedule
          post :release
        end
        member do
          put :calendar, action: :update_calendar
          put :holidays, action: :update_holidays
          get :public_holidays
          get :setup
          post :unlock
        end
      end

      # Ops Control
      scope "ops_control", controller: :ops_control, as: :ops_control do
        get "/", action: :index
        get "log", action: :log
        post "runs/:id/acknowledge", action: :acknowledge, as: :acknowledge
      end

      # Live Map
      scope "live_map", controller: :live_map, as: :live_map do
        get "/", action: :index
        get "vehicles/:id", action: :vehicle, as: :vehicle
        get "vehicles/:id/runs", action: :runs, as: :vehicle_runs
        get "runs/:id/track", action: :track, as: :run_track
      end

      # Reports
      scope "reports", controller: :reports, as: :reports do
        get "shuttle/options", action: :options, as: :shuttle_options
        get "shuttle", action: :shuttle
        get "shuttle/grid", action: :grid, as: :shuttle_grid
      end

      # Finance
      scope "finance", as: "finance" do
        resource :settings, controller: :finance_settings, only: %i[show update] do
          post :lock
          post :unlock
        end
        resources :invoices, controller: :client_invoices do
          collection do
            get :ready
            get :ad_hoc
            get :summary
            get :clients
            get :statement
          end
          member do
            post :issue
            post :void
            post :payments, action: :pay
            post :credit_note, action: :credit
            post :send, action: :send_invoice
          end
        end
        scope "operator_pay", controller: :operator_payments, as: :operator_pay do
          get :requests
          put :costs, action: :set_cost
          post :items, action: :create_item
          delete "items/:id", action: :destroy_item, as: :item
          post :approve
          post :ad_hoc
          get :batches
          get "batches/:id", action: :batch, as: :batch
          patch "batches/:id", action: :update_batch
          delete "batches/:id", action: :cancel_batch
          post "batches/:id/payments", action: :pay, as: :batch_payments
          post "batches/:id/mark_paid", action: :mark_paid, as: :batch_mark_paid
          post "batches/:id/bank_file", action: :bank_file, as: :batch_bank_file
          get "batches/:id/bank_file.csv", action: :download_bank_file, as: :batch_bank_file_csv, format: false, defaults: { format: :csv }
        end
        get "vehicles/pl", to: "vehicle_pl#fleet", as: :vehicles_pl
        get "vehicles/spikes", to: "vehicle_pl#spikes", as: :vehicles_spikes
        post "vehicles/spikes/ack", to: "vehicle_pl#ack_spike", as: :vehicles_spikes_ack
        get "vehicles/due", to: "vehicle_pl#due", as: :vehicles_due
        get "vehicles/:vehicle_id/pl", to: "vehicle_pl#vehicle", as: :vehicle_pl
        post "vehicles/:vehicle_id/entries", to: "vehicle_pl#create_entry", as: :vehicle_entries
        patch "vehicles/:vehicle_id/entries/:id", to: "vehicle_pl#update_entry", as: :vehicle_entry
        delete "vehicles/:vehicle_id/entries/:id", to: "vehicle_pl#destroy_entry"
        get "vehicles", to: "vehicle_financials#index"
        get "vehicles/:vehicle_id", to: "vehicle_financials#show", as: :vehicle
        patch "vehicles/:vehicle_id", to: "vehicle_financials#update"
        post "vehicles/:vehicle_id/instalments", to: "vehicle_financials#instalments", as: :vehicle_instalments
        get "documents", to: "finance_documents#index"
        get "documents/brand", to: "finance_documents#brand_info", as: :documents_brand
        get "documents/payment_notices/:id", to: "finance_documents#payment_notice", as: :payment_notice
        get "billing/:client_id", to: "client_billing#show", as: :billing
        patch "billing/:client_id", to: "client_billing#update"
      end

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
