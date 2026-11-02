class CreateCompanies < ActiveRecord::Migration[8.1]
  def change
    create_table :companies do |t|
      t.string  :name, null: false
      t.string  :short_name, limit: 12
      t.string  :code, null: false, limit: 6           # short code used in IDs (SD -> SD26000141)
      t.string  :country, null: false, default: "SG"
      t.string  :timezone, null: false, default: "Asia/Singapore"
      t.string  :theme_color
      t.string  :logo                                  # CarrierWave (ImageUploader)
      t.string  :date_format, null: false, default: "dmy"   # dmy | mdy | ymd | dmon
      t.string  :time_format, null: false, default: "24"    # 24 | 12
      t.string  :observed_holidays, null: false, default: "off" # off | work, for trips without a calendar
      t.boolean :business_units_enabled, null: false, default: false
      t.boolean :school_run_enabled, null: false, default: true          # add-on, set by Convoy Admin
      t.boolean :route_list_import_enabled, null: false, default: true   # add-on, set by Convoy Admin
      t.integer :external_vehicle_cap, null: false, default: 10
      t.string  :status, null: false, default: "active"     # active | suspended
      t.timestamps
    end
    add_index :companies, :code, unique: true
  end
end
