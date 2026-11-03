# School Bus › Stop Library and Stop Assignment: URA subzones (platform data, for Stop IDs), the company's shared stops
# and their PUDO points (photos, usage, bus sizes), each school's catchment of a stop (postal codes, drawn areas, points
# turned off), riders linked to a point by hand (or cut off from one), and photo requests to parents / drivers.
class CreateStopLibrary < ActiveRecord::Migration[8.1]
  def change
    create_table :ura_subzones do |t|
      t.string :code, null: false, index: { unique: true }
      t.string :name, null: false
      t.string :planning_area, null: false
      t.string :planning_area_code, null: false
      t.string :region, null: false
      t.jsonb :rings, null: false
      t.float :min_lat, null: false
      t.float :max_lat, null: false
      t.float :min_lng, null: false
      t.float :max_lng, null: false
    end
    add_index :ura_subzones, %i[min_lat max_lat]

    create_table :stops do |t|
      t.references :company, null: false, foreign_key: true, index: false
      t.string :code, null: false
      t.string :subzone_code, null: false
      t.string :name, null: false
      t.string :library_status, null: false, default: "approved"
      t.references :owner_school, foreign_key: { to_table: :schools }, index: false
      t.references :requested_by, foreign_key: { to_table: :users }, index: false
      t.timestamptz :requested_at
      t.string :former_codes, array: true, null: false, default: []
      t.references :created_by, foreign_key: { to_table: :users }, index: false
      t.datetime :discarded_at
      t.timestamps
    end
    add_index :stops, %i[company_id code], unique: true
    add_index :stops, %i[company_id library_status]

    create_table :stop_points do |t|
      t.references :stop, null: false, foreign_key: { on_delete: :cascade }, index: false
      t.string :suffix, null: false
      t.string :description
      t.string :usage, null: false, default: "both"
      t.string :sizes, array: true, null: false, default: []
      t.boolean :primary, null: false, default: false
      t.decimal :lat, precision: 10, scale: 7, null: false
      t.decimal :lng, precision: 10, scale: 7, null: false
      t.string :subzone_code
      t.string :street_view_url
      t.string :photo
      t.string :photo_original
      t.jsonb :photo_annotations
      t.string :photo_credit
      t.timestamptz :retired_at
      t.timestamps
    end
    add_index :stop_points, %i[stop_id suffix], unique: true

    create_table :school_stops do |t|
      t.references :company, null: false, foreign_key: true, index: false
      t.references :school, null: false, foreign_key: true, index: false
      t.references :stop, null: false, foreign_key: true
      t.string :postal_codes, array: true, null: false, default: []
      t.jsonb :areas, null: false, default: []
      t.bigint :off_point_ids, array: true, null: false, default: []
      t.timestamps
    end
    add_index :school_stops, %i[school_id stop_id], unique: true
    add_index :school_stops, :postal_codes, using: :gin

    create_table :rider_point_links do |t|
      t.references :company, null: false, foreign_key: true, index: false
      t.references :school, null: false, foreign_key: true, index: false
      t.references :stop_point, null: false, foreign_key: { on_delete: :cascade }
      t.string :kind, null: false
      t.string :rid
      t.string :postal
      t.references :created_by, foreign_key: { to_table: :users }, index: false
      t.timestamps
    end
    add_index :rider_point_links, %i[school_id kind rid]
    add_index :rider_point_links, %i[school_id kind postal]
    add_check_constraint :rider_point_links, "num_nonnulls(rid, postal) = 1", name: "rider_point_links_one_target"

    create_table :stop_photo_requests do |t|
      t.references :company, null: false, foreign_key: true, index: false
      t.references :stop_point, null: false, foreign_key: { on_delete: :cascade }, index: false
      t.string :audience, null: false, default: "parents"
      t.references :school_rider, foreign_key: { on_delete: :nullify }, index: false
      t.integer :max_submissions, null: false, default: 6
      t.string :status, null: false, default: "open"
      t.boolean :auto, null: false, default: false
      t.references :created_by, foreign_key: { to_table: :users }, index: false
      t.timestamps
    end
    add_index :stop_photo_requests, %i[stop_point_id status]

    create_table :stop_photo_submissions do |t|
      t.references :company, null: false, foreign_key: true, index: false
      t.references :stop_photo_request, null: false, foreign_key: { on_delete: :cascade }
      t.string :submitted_by_name, null: false
      t.string :role, null: false
      t.string :photo, null: false
      t.string :street_view_url
      t.jsonb :annotations
      t.string :status, null: false, default: "pending"
      t.timestamptz :submitted_at, null: false
      t.timestamps
    end

    add_column :companies, :stop_photo_auto_driver, :boolean, null: false, default: false
    add_column :companies, :stop_photo_auto_parent, :boolean, null: false, default: false
    add_column :schools, :stops_changed_at, :timestamptz
  end
end
