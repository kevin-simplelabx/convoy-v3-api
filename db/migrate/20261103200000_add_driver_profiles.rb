# Convoy Driver app profile: the portable profile on the account (Personal Details, Singpass, photo), the driver's
# licences, the company's copy of what was shared (driver_kyc_profiles gets the licence list), and what the app shows
# about the company: operations contacts on Company Settings and Company Links.
class AddDriverProfiles < ActiveRecord::Migration[8.1]
  def change
    { date_of_birth: :date, nationality: :string, residential_status: :string, id_number: :text, id_number_masked: :string,
      address: :text, postal_code: :string, photo: :string, singpass_verified_at: :datetime }.each do |name, type|
      add_column :driver_accounts, name, type
    end
    add_column :driver_accounts, :singpass_fields, :string, array: true, null: false, default: []

    create_table :driver_licences do |t|
      t.references :driver_account, null: false, foreign_key: { on_delete: :cascade }
      t.string :kind, null: false
      t.string :name, null: false
      t.string :classes
      t.string :number
      t.date :issued_on
      t.date :expires_on
      t.string :card_front
      t.string :card_back
      t.timestamps
    end

    add_column :driver_kyc_profiles, :licences, :jsonb, null: false, default: []

    %i[ops_phone ops_hours ops_whatsapp ops_email].each { add_column :companies, it, :string }
    add_column :companies, :depot_address, :text

    create_table :company_links do |t|
      t.references :company, null: false, foreign_key: true
      t.string :title, null: false
      t.string :url, null: false
      t.string :note
      t.integer :position, null: false, default: 0
      t.timestamps
    end
  end
end
