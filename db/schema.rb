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

ActiveRecord::Schema[8.1].define(version: 2026_10_13_163855) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "attendants", force: :cascade do |t|
    t.bigint "company_id", null: false
    t.string "name"
    t.string "contact"
    t.string "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_attendants_on_company_id"
  end

  create_table "companies", force: :cascade do |t|
    t.string "name"
    t.text "logo"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "settings"
  end

  create_table "datasets", force: :cascade do |t|
    t.bigint "school_id", null: false
    t.date "effective_from", null: false
    t.string "file_name", default: "upload.csv"
    t.string "uploaded_by", default: ""
    t.jsonb "rows", default: []
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["school_id", "effective_from"], name: "index_datasets_on_school_and_date"
    t.index ["school_id"], name: "index_datasets_on_school_id"
  end

  create_table "drafts", force: :cascade do |t|
    t.bigint "school_id", null: false
    t.jsonb "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["school_id"], name: "index_drafts_on_school_id", unique: true
  end

  create_table "plans", force: :cascade do |t|
    t.bigint "school_id", null: false
    t.jsonb "data", default: [], null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["school_id"], name: "index_plans_on_school_id", unique: true
  end

  create_table "riders", force: :cascade do |t|
    t.bigint "school_id", null: false
    t.string "rid"
    t.string "name", null: false
    t.string "gender", default: ""
    t.string "grade", default: ""
    t.string "address", default: ""
    t.string "postal", default: ""
    t.decimal "lat", precision: 10, scale: 7
    t.decimal "lng", precision: 10, scale: 7
    t.boolean "am", default: true
    t.boolean "pm", default: true
    t.string "cca", default: ""
    t.date "start_date"
    t.date "end_date"
    t.string "parent_name", default: ""
    t.string "parent_contact", default: ""
    t.string "remarks", default: ""
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["school_id"], name: "index_riders_on_school_id"
  end

  create_table "schools", force: :cascade do |t|
    t.bigint "company_id", null: false
    t.string "name", null: false
    t.string "short", default: ""
    t.string "address", default: ""
    t.string "postal", default: ""
    t.decimal "lat", precision: 10, scale: 7
    t.decimal "lng", precision: 10, scale: 7
    t.jsonb "labels", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_schools_on_company_id"
  end

  create_table "stop_libraries", force: :cascade do |t|
    t.bigint "company_id", null: false
    t.jsonb "lib", default: [], null: false
    t.jsonb "counters", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_stop_libraries_on_company_id", unique: true
  end

  create_table "trips", id: :string, force: :cascade do |t|
    t.bigint "company_id", null: false
    t.bigint "school_id"
    t.bigint "vehicle_id"
    t.string "kind"
    t.string "title"
    t.string "customer"
    t.date "trip_date"
    t.string "start_time"
    t.string "end_time"
    t.string "pickup"
    t.string "dropoff"
    t.integer "pax", default: 0
    t.integer "buses", default: 1
    t.decimal "price", precision: 10, scale: 2, default: "0.0"
    t.boolean "rate_hr", default: false
    t.integer "days", default: [], array: true
    t.date "until_date"
    t.string "end_mode", default: "never"
    t.integer "occ_count"
    t.string "flight"
    t.text "notes"
    t.string "by_user"
    t.boolean "sample", default: false
    t.integer "no"
    t.date "no_from"
    t.integer "n_n", default: 1
    t.boolean "n_r", default: false
    t.string "pair_id"
    t.boolean "is_return", default: false
    t.boolean "skip_ph", default: true
    t.jsonb "extra", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id", "trip_date"], name: "index_trips_on_company_id_and_trip_date"
    t.index ["company_id"], name: "index_trips_on_company_id"
    t.index ["vehicle_id"], name: "index_trips_on_vehicle_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "name", default: "", null: false
    t.string "role", default: "user", null: false
    t.string "permissions", default: [], null: false, array: true
    t.bigint "company_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_users_on_company_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "vehicles", force: :cascade do |t|
    t.bigint "company_id", null: false
    t.string "plate"
    t.string "vehicle_type"
    t.integer "seats"
    t.string "driver_name"
    t.string "driver_contact"
    t.string "notes"
    t.string "operator_id"
    t.string "operator_name"
    t.string "operator_contact"
    t.string "operator_phone"
    t.string "tags"
    t.text "photo"
    t.text "driver_photo"
    t.boolean "sample"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_vehicles_on_company_id"
  end

  add_foreign_key "attendants", "companies"
  add_foreign_key "datasets", "schools"
  add_foreign_key "drafts", "schools"
  add_foreign_key "plans", "schools"
  add_foreign_key "riders", "schools"
  add_foreign_key "schools", "companies"
  add_foreign_key "stop_libraries", "companies"
  add_foreign_key "trips", "companies"
  add_foreign_key "vehicles", "companies"
end
