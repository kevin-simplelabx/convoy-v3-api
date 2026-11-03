# School Bus › Route Plans: the company's routing parameters, each routing run (input and engine result kept as they
# were), and what a plan needs beyond the Scheduler's use of it — where it came from, its summary and unassigned riders,
# adoption, Out of Date — per route the engine's figures and hand edits, per stop the Stop Library stop and point, and
# the riders at each stop.
class CreateRouting < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    create_table :routing_settings do |t|
      t.references :company, null: false, foreign_key: true, index: { unique: true }
      t.jsonb :params, null: false, default: {}
      t.references :updated_by, foreign_key: { to_table: :users }, index: false
      t.timestamps
    end

    create_table :routing_runs do |t|
      t.references :company, null: false, foreign_key: true, index: false
      t.references :school, null: false, foreign_key: true, index: false
      t.string :session, null: false
      t.date :plan_date, null: false
      t.string :status, null: false, default: "queued"
      t.jsonb :params, null: false, default: {}
      t.jsonb :input, null: false, default: {}
      t.jsonb :result
      t.text :error
      t.string :no_stop_rids, array: true, null: false, default: []
      t.string :conflict_rids, array: true, null: false, default: []
      t.integer :ms
      t.references :created_by, foreign_key: { to_table: :users }, index: false
      t.timestamptz :started_at
      t.timestamptz :finished_at
      t.timestamps
    end
    add_index :routing_runs, %i[school_id created_at]

    create_table :plan_comments do |t|
      t.references :company, null: false, foreign_key: true, index: false
      t.references :school_plan, null: false, foreign_key: { on_delete: :cascade }
      t.references :user, foreign_key: true, index: false
      t.text :body, null: false
      t.timestamps
    end

    create_table :school_route_riders do |t|
      t.references :company, null: false, foreign_key: true, index: false
      t.references :school_route, null: false, foreign_key: { on_delete: :cascade }
      t.references :school_route_stop, null: false, foreign_key: { on_delete: :cascade }, index: false
      t.string :rid, null: false
    end
    add_index :school_route_riders, :school_route_stop_id
    add_index :school_route_riders, :rid

    add_column :school_plans, :source, :string, null: false, default: "manual"
    add_column :school_plans, :priority, :string
    add_column :school_plans, :params, :jsonb
    add_column :school_plans, :summary, :jsonb
    add_column :school_plans, :unassigned, :jsonb, null: false, default: []
    add_column :school_plans, :stale, :boolean, null: false, default: false
    add_column :school_plans, :adopted_at, :timestamptz
    add_reference :school_plans, :routing_run, index: { algorithm: :concurrently }, foreign_key: { validate: false, on_delete: :nullify }
    add_reference :school_plans, :adopted_by, index: false, foreign_key: { to_table: :users, validate: false }
    add_reference :school_plans, :created_by, index: false, foreign_key: { to_table: :users, validate: false }

    add_column :school_routes, :route_key, :string
    add_column :school_routes, :bus_type, :string
    add_column :school_routes, :seats, :integer
    add_column :school_routes, :student_seats, :integer
    add_column :school_routes, :capacity, :integer
    add_column :school_routes, :floor, :integer
    add_column :school_routes, :fill, :decimal, precision: 5, scale: 4
    add_column :school_routes, :span_seconds, :integer
    add_column :school_routes, :ride_minutes, :integer
    add_column :school_routes, :badges, :string, array: true, null: false, default: []
    add_column :school_routes, :locked, :boolean, null: false, default: false
    add_column :school_routes, :hidden, :boolean, null: false, default: false
    add_column :school_routes, :edited, :boolean, null: false, default: false
    add_column :school_routes, :manual, :boolean, null: false, default: false
    add_column :school_routes, :vias, :jsonb, null: false, default: []
    add_column :school_routes, :engine_route, :jsonb

    add_column :school_route_stops, :dwell_seconds, :integer
    add_reference :school_route_stops, :stop, index: { algorithm: :concurrently }, foreign_key: { validate: false }
    add_reference :school_route_stops, :stop_point, index: { algorithm: :concurrently }, foreign_key: { validate: false }
  end
end
