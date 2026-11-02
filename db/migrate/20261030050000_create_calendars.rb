class CreateCalendars < ActiveRecord::Migration[8.1]
  def change
    # Built-in company calendar: public holidays (trips, rates and pay follow it).
    create_table :public_holidays do |t|
      t.references :company, null: false, foreign_key: true
      t.date    :date, null: false
      t.string  :name, null: false
      t.boolean :observed, null: false, default: false   # given in place of a holiday on a Sunday
      t.timestamps
    end
    add_index :public_holidays, %i[company_id date], unique: true

    # User calendars picked by recurring trips (school or general).
    create_table :calendars do |t|
      t.references :company, null: false, foreign_key: true
      t.string   :name, null: false
      t.string   :kind, null: false                        # school | general
      t.string   :observed_holidays, null: false, default: "off" # off | work
      t.datetime :discarded_at
      t.timestamps
    end
    add_index :calendars, %i[company_id name], unique: true, where: "discarded_at IS NULL"
    add_index :calendars, :discarded_at

    # One entry (one day or a range) on a calendar.
    create_table :calendar_days do |t|
      t.references :company, null: false, foreign_key: true
      t.references :calendar, null: false, foreign_key: true
      t.string  :kind, null: false      # school: hol ns early late | general: off shift oil work
      t.date    :starts_on, null: false
      t.date    :ends_on, null: false
      t.string  :label
      t.integer :usual_time             # minutes after midnight (early / late)
      t.integer :new_time               # minutes after midnight (early / late)
      t.integer :shift_minutes          # +/- minutes (shift)
      t.date    :in_place_of            # holiday an Off in Lieu replaces
      t.boolean :notify_drivers, null: false, default: false
      t.timestamps
    end
    add_index :calendar_days, %i[calendar_id starts_on ends_on]
    add_check_constraint :calendar_days, "ends_on >= starts_on", name: "calendar_days_range"
  end
end
