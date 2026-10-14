class CreateTrips < ActiveRecord::Migration[8.1]
  def change
    create_table :trips, id: false, force: :cascade do |t|
      t.string  :id,         null: false, primary_key: true
      t.references :company, null: false, foreign_key: true
      t.bigint  :school_id
      t.bigint  :vehicle_id
      t.string  :kind
      t.string  :title
      t.string  :customer
      t.date    :trip_date
      t.string  :start_time
      t.string  :end_time
      t.string  :pickup
      t.string  :dropoff
      t.integer :pax,       default: 0
      t.integer :buses,     default: 1
      t.decimal :price,     precision: 10, scale: 2, default: 0
      t.boolean :rate_hr,   default: false
      t.integer :days,      array: true, default: []
      t.date    :until_date
      t.string  :end_mode,  default: "never"
      t.integer :occ_count
      t.string  :flight
      t.text    :notes
      t.string  :by_user
      t.boolean :sample,    default: false
      t.integer :no
      t.date    :no_from
      t.integer :n_n,       default: 1
      t.boolean :n_r,       default: false
      t.string  :pair_id
      t.boolean :is_return, default: false
      t.boolean :skip_ph,   default: true
      t.jsonb   :extra,     default: {}
      t.timestamps
    end

    add_index :trips, [ :company_id, :trip_date ]
    add_index :trips, :vehicle_id
  end
end
