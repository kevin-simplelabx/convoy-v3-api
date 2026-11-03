# Convoy Admin > Discover: Convoy's own space in the Convoy App (Home banners, the Discover tab). Advertisers pay a
# listing fee a month and a commission on what is sold in the app. A placement is a bookable trip, a programme, an
# advert or Convoy's own news, with where and to whom it shows, when it runs and its state. views / taps / sold are
# counted by the Convoy App.
class CreateDiscover < ActiveRecord::Migration[8.1]
  def change
    create_table :discover_advertisers do |t|
      t.string :name, null: false
      t.string :kind, null: false, default: "brand"
      t.boolean :premier, null: false, default: false
      t.string :country, null: false, default: "SG"
      t.decimal :listing_fee, precision: 12, scale: 2, null: false, default: 0
      t.decimal :commission_pct, precision: 5, scale: 2, null: false, default: 0
      t.string :email
      t.datetime :discarded_at
      t.timestamps
    end
    add_index :discover_advertisers, :name, unique: true, where: "discarded_at IS NULL"
    add_check_constraint :discover_advertisers, "kind IN ('tc', 'attr', 'prog', 'brand')", name: "discover_advertisers_kind"

    create_table :discover_placements do |t|
      t.references :discover_advertiser, foreign_key: true
      t.string :kind, null: false, default: "trip"
      t.string :kicker
      t.string :title, null: false
      t.string :subtitle
      t.string :background, null: false, default: "#004F59"
      t.string :image
      t.string :cta, null: false, default: "Book Now"
      t.decimal :price, precision: 12, scale: 2
      t.decimal :child_price, precision: 12, scale: 2
      t.integer :seats
      t.date :event_on
      t.string :pickup_points
      t.references :run_by_company, foreign_key: { to_table: :companies }
      t.boolean :bus_included, null: false, default: true
      t.boolean :sold_to_public, null: false, default: false
      t.string :link
      t.string :promo_code
      t.boolean :show_home, null: false, default: true
      t.boolean :show_discover, null: false, default: true
      t.boolean :push_once, null: false, default: false
      t.date :starts_on, null: false
      t.date :ends_on, null: false
      t.string :slot, null: false, default: "std"
      t.string :audiences, array: true, null: false, default: %w[parents]
      t.string :area, null: false, default: "all"
      t.string :school_level, null: false, default: "any"
      t.decimal :listing_fee, precision: 12, scale: 2, null: false, default: 0
      t.decimal :commission_pct, precision: 5, scale: 2, null: false, default: 0
      t.string :status, null: false, default: "draft"
      t.datetime :ended_at
      t.integer :views, null: false, default: 0
      t.integer :taps, null: false, default: 0
      t.integer :sold, null: false, default: 0
      t.references :created_by, foreign_key: { to_table: :users }
      t.timestamps
    end
    add_index :discover_placements, %i[status starts_on ends_on]
    add_check_constraint :discover_placements, "kind IN ('trip', 'prog', 'ad', 'news')", name: "discover_placements_kind"
    add_check_constraint :discover_placements, "status IN ('draft', 'live', 'paused')", name: "discover_placements_status"
  end
end
