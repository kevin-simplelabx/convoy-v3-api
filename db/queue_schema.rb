# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_10_30_050300) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "attendants", force: :cascade do |t|
    t.bigint "company_id", null: false
    t.string "name", null: false
    t.string "phone"
    t.string "photo"
    t.text "notes"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_attendants_on_company_id"
    t.index ["discarded_at"], name: "index_attendants_on_discarded_at"
  end

  create_table "audits", force: :cascade do |t|
    t.integer "auditable_id"
    t.string "auditable_type"
    t.integer "associated_id"
    t.string "associated_type"
    t.integer "user_id"
    t.string "user_type"
    t.string "username"
    t.string "action"
    t.text "audited_changes"
    t.integer "version", default: 0
    t.string "comment"
    t.string "remote_address"
    t.string "request_uuid"
    t.datetime "created_at"
    t.index ["associated_type", "associated_id"], name: "associated_index"
    t.index ["auditable_type", "auditable_id", "version"], name: "auditable_index"
    t.index ["created_at"], name: "index_audits_on_created_at"
    t.index ["request_uuid"], name: "index_audits_on_request_uuid"
    t.index ["user_id", "user_type"], name: "user_index"
  end

  create_table "calendar_days", force: :cascade do |t|
    t.bigint "company_id", null: false
    t.bigint "calendar_id", null: false
    t.string "kind", null: false
    t.date "starts_on", null: false
    t.date "ends_on", null: false
    t.string "label"
    t.integer "usual_time"
    t.integer "new_time"
    t.integer "shift_minutes"
    t.date "in_place_of"
    t.boolean "notify_drivers", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["calendar_id", "starts_on", "ends_on"], name: "index_calendar_days_on_calendar_id_and_starts_on_and_ends_on"
    t.index ["calendar_id"], name: "index_calendar_days_on_calendar_id"
    t.index ["company_id"], name: "index_calendar_days_on_company_id"
    t.check_constraint "ends_on >= starts_on", name: "calendar_days_range"
  end

  create_table "calendars", force: :cascade do |t|
    t.bigint "company_id", null: false
    t.string "name", null: false
    t.string "kind", null: false
    t.string "observed_holidays", default: "off", null: false
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id", "name"], name: "index_calendars_on_company_id_and_name", unique: true, where: "(discarded_at IS NULL)"
    t.index ["company_id"], name: "index_calendars_on_company_id"
    t.index ["discarded_at"], name: "index_calendars_on_discarded_at"
  end

  create_table "client_end_customers", force: :cascade do |t|
    t.bigint "company_id", null: false
    t.bigint "client_id", null: false
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_id", "name"], name: "index_client_end_customers_on_client_id_and_name", unique: true
    t.index ["client_id"], name: "index_client_end_customers_on_client_id"
    t.index ["company_id"], name: "index_client_end_customers_on_company_id"
  end

  create_table "client_pickup_points", force: :cascade do |t|
    t.bigint "company_id", null: false
    t.bigint "client_id", null: false
    t.string "name", null: false
    t.text "address"
    t.string "postal_code"
    t.decimal "lat", precision: 10, scale: 7
    t.decimal "lng", precision: 10, scale: 7
    t.text "note"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_id", "name"], name: "index_client_pickup_points_on_client_id_and_name", unique: true
    t.index ["client_id"], name: "index_client_pickup_points_on_client_id"
    t.index ["company_id"], name: "index_client_pickup_points_on_company_id"
  end

  create_table "client_sites", force: :cascade do |t|
    t.bigint "company_id", null: false
    t.bigint "client_id", null: false
    t.string "name", null: false
    t.text "address"
    t.decimal "lat", precision: 10, scale: 7
    t.decimal "lng", precision: 10, scale: 7
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_id", "name"], name: "index_client_sites_on_client_id_and_name", unique: true
    t.index ["client_id"], name: "index_client_sites_on_client_id"
    t.index ["company_id"], name: "index_client_sites_on_company_id"
  end

  create_table "clients", force: :cascade do |t|
    t.bigint "company_id", null: false
    t.string "code", null: false
    t.string "kind", default: "company", null: false
    t.string "name", null: false
    t.string "uen"
    t.string "contact_name"
    t.string "phone"
    t.string "email"
    t.text "billing_address"
    t.integer "on_time_allowance", default: 3, null: false
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id", "code"], name: "index_clients_on_company_id_and_code", unique: true
    t.index ["company_id", "name"], name: "index_clients_on_company_id_and_name", unique: true, where: "(discarded_at IS NULL)"
    t.index ["company_id"], name: "index_clients_on_company_id"
    t.index ["discarded_at"], name: "index_clients_on_discarded_at"
  end

  create_table "companies", force: :cascade do |t|
    t.string "name", null: false
    t.string "short_name", limit: 12
    t.string "code", limit: 6, null: false
    t.string "country", default: "SG", null: false
    t.string "timezone", default: "Asia/Singapore", null: false
    t.string "theme_color"
    t.string "logo"
    t.string "date_format", default: "dmy", null: false
    t.string "time_format", default: "24", null: false
    t.string "observed_holidays", default: "off", null: false
    t.boolean "business_units_enabled", default: false, null: false
    t.boolean "school_run_enabled", default: true, null: false
    t.boolean "route_list_import_enabled", default: true, null: false
    t.integer "external_vehicle_cap", default: 10, null: false
    t.string "status", default: "active", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_companies_on_code", unique: true
  end

  create_table "company_sequences", force: :cascade do |t|
    t.bigint "company_id", null: false
    t.string "name", null: false
    t.bigint "value", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id", "name"], name: "index_company_sequences_on_company_id_and_name", unique: true
    t.index ["company_id"], name: "index_company_sequences_on_company_id"
  end

  create_table "disabled_vehicle_types", force: :cascade do |t|
    t.bigint "company_id", null: false
    t.bigint "vehicle_type_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id", "vehicle_type_id"], name: "index_disabled_vehicle_types_on_company_id_and_vehicle_type_id", unique: true
    t.index ["company_id"], name: "index_disabled_vehicle_types_on_company_id"
    t.index ["vehicle_type_id"], name: "index_disabled_vehicle_types_on_vehicle_type_id"
  end

  create_table "drivers", force: :cascade do |t|
    t.bigint "company_id", null: false
    t.string "name", null: false
    t.string "phone", null: false
    t.string "photo"
    t.string "status", default: "pending", null: false
    t.datetime "invited_at"
    t.datetime "responded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id", "phone"], name: "index_drivers_on_company_id_and_phone", unique: true
    t.index ["company_id", "status"], name: "index_drivers_on_company_id_and_status"
    t.index ["company_id"], name: "index_drivers_on_company_id"
  end

  create_table "operator_drivers", force: :cascade do |t|
    t.bigint "company_id", null: false
    t.bigint "operator_id", null: false
    t.bigint "vehicle_id"
    t.string "name", null: false
    t.string "phone", null: false
    t.string "photo"
    t.text "notes"
    t.string "status", default: "pending", null: false
    t.datetime "invited_at"
    t.datetime "responded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id", "phone"], name: "index_operator_drivers_on_company_id_and_phone", unique: true
    t.index ["company_id"], name: "index_operator_drivers_on_company_id"
    t.index ["operator_id"], name: "index_operator_drivers_on_operator_id"
    t.index ["vehicle_id"], name: "index_operator_drivers_on_vehicle_id"
    t.index ["vehicle_id"], name: "index_operator_drivers_one_per_vehicle", unique: true, where: "(vehicle_id IS NOT NULL)"
  end

  create_table "operators", force: :cascade do |t|
    t.bigint "company_id", null: false
    t.string "name", null: false
    t.string "kind", default: "managed", null: false
    t.string "uen"
    t.string "contact_name"
    t.string "phone"
    t.string "email"
    t.string "payment_method"
    t.string "paynow_uen"
    t.string "bank_code"
    t.string "branch_code"
    t.string "account_number"
    t.string "account_name"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id", "kind", "name"], name: "index_operators_on_company_id_and_kind_and_name", unique: true, where: "(discarded_at IS NULL)"
    t.index ["company_id"], name: "index_operators_on_company_id"
    t.index ["discarded_at"], name: "index_operators_on_discarded_at"
  end

  create_table "public_holidays", force: :cascade do |t|
    t.bigint "company_id", null: false
    t.date "date", null: false
    t.string "name", null: false
    t.boolean "observed", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id", "date"], name: "index_public_holidays_on_company_id_and_date", unique: true
    t.index ["company_id"], name: "index_public_holidays_on_company_id"
  end

  create_table "solid_queue_batch_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.bigint "batch_id", null: false
    t.datetime "created_at", null: false
    t.index ["batch_id"], name: "index_solid_queue_batch_executions_on_batch_id"
    t.index ["job_id"], name: "index_solid_queue_batch_executions_on_job_id", unique: true
  end

  create_table "solid_queue_batches", force: :cascade do |t|
    t.string "active_job_batch_id"
    t.string "description"
    t.text "on_finish"
    t.text "on_success"
    t.text "on_failure"
    t.text "metadata"
    t.integer "total_jobs", default: 0, null: false
    t.integer "completed_jobs", default: 0, null: false
    t.integer "failed_jobs", default: 0, null: false
    t.datetime "enqueued_at"
    t.datetime "finished_at"
    t.datetime "failed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active_job_batch_id"], name: "index_solid_queue_batches_on_active_job_batch_id", unique: true
    t.index ["finished_at"], name: "index_solid_queue_batches_on_finished_at"
  end

  create_table "solid_queue_blocked_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.string "concurrency_key", null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.index ["concurrency_key", "priority", "job_id"], name: "index_solid_queue_blocked_executions_for_release"
    t.index ["expires_at", "concurrency_key"], name: "index_solid_queue_blocked_executions_for_maintenance"
    t.index ["job_id"], name: "index_solid_queue_blocked_executions_on_job_id", unique: true
  end

  create_table "solid_queue_claimed_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.bigint "process_id"
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_claimed_executions_on_job_id", unique: true
    t.index ["process_id", "job_id"], name: "index_solid_queue_claimed_executions_on_process_id_and_job_id"
  end

  create_table "solid_queue_failed_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.text "error"
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_failed_executions_on_job_id", unique: true
  end

  create_table "solid_queue_jobs", force: :cascade do |t|
    t.string "queue_name", null: false
    t.string "class_name", null: false
    t.text "arguments"
    t.integer "priority", default: 0, null: false
    t.string "active_job_id"
    t.datetime "scheduled_at"
    t.datetime "finished_at"
    t.string "concurrency_key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "batch_id"
    t.index ["active_job_id"], name: "index_solid_queue_jobs_on_active_job_id"
    t.index ["batch_id"], name: "index_solid_queue_jobs_on_batch_id"
    t.index ["class_name"], name: "index_solid_queue_jobs_on_class_name"
    t.index ["finished_at"], name: "index_solid_queue_jobs_on_finished_at"
    t.index ["queue_name", "finished_at"], name: "index_solid_queue_jobs_for_filtering"
    t.index ["scheduled_at", "finished_at"], name: "index_solid_queue_jobs_for_alerting"
  end

  create_table "solid_queue_pauses", force: :cascade do |t|
    t.string "queue_name", null: false
    t.datetime "created_at", null: false
    t.index ["queue_name"], name: "index_solid_queue_pauses_on_queue_name", unique: true
  end

  create_table "solid_queue_processes", force: :cascade do |t|
    t.string "kind", null: false
    t.datetime "last_heartbeat_at", null: false
    t.bigint "supervisor_id"
    t.integer "pid", null: false
    t.string "hostname"
    t.text "metadata"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.index ["last_heartbeat_at"], name: "index_solid_queue_processes_on_last_heartbeat_at"
    t.index ["name", "supervisor_id"], name: "index_solid_queue_processes_on_name_and_supervisor_id", unique: true
    t.index ["supervisor_id"], name: "index_solid_queue_processes_on_supervisor_id"
  end

  create_table "solid_queue_ready_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_ready_executions_on_job_id", unique: true
    t.index ["priority", "job_id"], name: "index_solid_queue_poll_all"
    t.index ["queue_name", "priority", "job_id"], name: "index_solid_queue_poll_by_queue"
  end

  create_table "solid_queue_recurring_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "task_key", null: false
    t.datetime "run_at", null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_recurring_executions_on_job_id", unique: true
    t.index ["task_key", "run_at"], name: "index_solid_queue_recurring_executions_on_task_key_and_run_at", unique: true
  end

  create_table "solid_queue_recurring_tasks", force: :cascade do |t|
    t.string "key", null: false
    t.string "schedule", null: false
    t.string "command", limit: 2048
    t.string "class_name"
    t.text "arguments"
    t.string "queue_name"
    t.integer "priority", default: 0
    t.boolean "static", default: true, null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_solid_queue_recurring_tasks_on_key", unique: true
    t.index ["static"], name: "index_solid_queue_recurring_tasks_on_static"
  end

  create_table "solid_queue_scheduled_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "scheduled_at", null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_scheduled_executions_on_job_id", unique: true
    t.index ["scheduled_at", "priority", "job_id"], name: "index_solid_queue_dispatch_all"
  end

  create_table "solid_queue_semaphores", force: :cascade do |t|
    t.string "key", null: false
    t.integer "value", default: 1, null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["expires_at"], name: "index_solid_queue_semaphores_on_expires_at"
    t.index ["key", "value"], name: "index_solid_queue_semaphores_on_key_and_value"
    t.index ["key"], name: "index_solid_queue_semaphores_on_key", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.bigint "company_id"
    t.string "name", null: false
    t.string "mobile"
    t.string "avatar"
    t.string "role", default: "member", null: false
    t.boolean "owner", default: false, null: false
    t.string "permissions", default: [], null: false, array: true
    t.string "status", default: "active", null: false
    t.datetime "last_seen_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_users_on_company_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["permissions"], name: "index_users_on_permissions", using: :gin
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "vehicle_driver_schedules", force: :cascade do |t|
    t.bigint "company_id", null: false
    t.bigint "vehicle_id", null: false
    t.bigint "driver_id"
    t.date "starts_on", null: false
    t.bigint "created_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_vehicle_driver_schedules_on_company_id"
    t.index ["created_by_id"], name: "index_vehicle_driver_schedules_on_created_by_id"
    t.index ["driver_id", "starts_on"], name: "index_vehicle_driver_schedules_on_driver_id_and_starts_on"
    t.index ["driver_id"], name: "index_vehicle_driver_schedules_on_driver_id"
    t.index ["vehicle_id", "starts_on"], name: "index_vehicle_driver_schedules_on_vehicle_id_and_starts_on", unique: true
    t.index ["vehicle_id"], name: "index_vehicle_driver_schedules_on_vehicle_id"
  end

  create_table "vehicle_teams", force: :cascade do |t|
    t.bigint "company_id", null: false
    t.string "name", null: false
    t.string "color", default: "#0B6E6E", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id", "name"], name: "index_vehicle_teams_on_company_id_and_name", unique: true
    t.index ["company_id"], name: "index_vehicle_teams_on_company_id"
  end

  create_table "vehicle_types", force: :cascade do |t|
    t.string "key", null: false
    t.string "name", null: false
    t.integer "seats", null: false
    t.string "tyre_layout", default: "1-1", null: false
    t.integer "position", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_vehicle_types_on_key", unique: true
  end

  create_table "vehicles", force: :cascade do |t|
    t.bigint "company_id", null: false
    t.bigint "operator_id"
    t.bigint "vehicle_team_id"
    t.string "plate", null: false
    t.integer "seats"
    t.string "make"
    t.string "model"
    t.integer "year_made"
    t.string "tags", default: [], null: false, array: true
    t.text "notes"
    t.string "photo"
    t.string "driver_name"
    t.string "driver_phone"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id", "plate"], name: "index_vehicles_on_company_id_and_plate", unique: true, where: "(discarded_at IS NULL)"
    t.index ["company_id", "seats"], name: "index_vehicles_on_company_id_and_seats"
    t.index ["company_id"], name: "index_vehicles_on_company_id"
    t.index ["discarded_at"], name: "index_vehicles_on_discarded_at"
    t.index ["operator_id"], name: "index_vehicles_on_operator_id"
    t.index ["tags"], name: "index_vehicles_on_tags", using: :gin
    t.index ["vehicle_team_id"], name: "index_vehicles_on_vehicle_team_id"
  end

  add_foreign_key "attendants", "companies"
  add_foreign_key "calendar_days", "calendars"
  add_foreign_key "calendar_days", "companies"
  add_foreign_key "calendars", "companies"
  add_foreign_key "client_end_customers", "clients"
  add_foreign_key "client_end_customers", "companies"
  add_foreign_key "client_pickup_points", "clients"
  add_foreign_key "client_pickup_points", "companies"
  add_foreign_key "client_sites", "clients"
  add_foreign_key "client_sites", "companies"
  add_foreign_key "clients", "companies"
  add_foreign_key "company_sequences", "companies"
  add_foreign_key "disabled_vehicle_types", "companies"
  add_foreign_key "disabled_vehicle_types", "vehicle_types"
  add_foreign_key "drivers", "companies"
  add_foreign_key "operator_drivers", "companies"
  add_foreign_key "operator_drivers", "operators"
  add_foreign_key "operator_drivers", "vehicles"
  add_foreign_key "operators", "companies"
  add_foreign_key "public_holidays", "companies"
  add_foreign_key "solid_queue_batch_executions", "solid_queue_batches", column: "batch_id", on_delete: :cascade
  add_foreign_key "solid_queue_batch_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_blocked_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_claimed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_failed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_ready_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_recurring_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_scheduled_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "users", "companies"
  add_foreign_key "vehicle_driver_schedules", "companies"
  add_foreign_key "vehicle_driver_schedules", "drivers"
  add_foreign_key "vehicle_driver_schedules", "users", column: "created_by_id"
  add_foreign_key "vehicle_driver_schedules", "vehicles"
  add_foreign_key "vehicle_teams", "companies"
  add_foreign_key "vehicles", "companies"
  add_foreign_key "vehicles", "operators"
  add_foreign_key "vehicles", "vehicle_teams"
end
