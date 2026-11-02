class AddVehicleDocuments < ActiveRecord::Migration[8.1]
  def change
    # Log card details (current values on the vehicle).
    add_column :vehicles, :chassis_number, :string
    add_column :vehicles, :engine_number, :string
    add_column :vehicles, :registered_on, :date
    add_column :vehicles, :coe_expires_on, :date
    add_column :vehicles, :road_tax_expires_on, :date

    # Log card files: one current, earlier ones are Past Log Cards.
    create_table :vehicle_log_cards do |t|
      t.references :company, null: false, foreign_key: true
      t.references :vehicle, null: false, foreign_key: true
      t.references :uploaded_by, foreign_key: { to_table: :users }
      t.string   :file, null: false                 # CarrierWave (DocumentUploader)
      t.boolean  :current, null: false, default: true
      t.string   :plate_on_card                      # plate read from the card
      t.boolean  :plate_conflict, null: false, default: false # card plate differs: blocks saving the vehicle until picked
      t.timestamps
    end
    add_index :vehicle_log_cards, :vehicle_id, unique: true, where: "current", name: "index_vehicle_log_cards_one_current"

    # Insurance policies: one current, renewed ones are Past Policies.
    create_table :vehicle_insurance_policies do |t|
      t.references :company, null: false, foreign_key: true
      t.references :vehicle, null: false, foreign_key: true
      t.boolean :current, null: false, default: true
      t.string  :insurer
      t.string  :policy_number
      t.string  :cover_type
      t.date    :starts_on
      t.date    :ends_on
      t.decimal :excess, precision: 12, scale: 2
      t.decimal :excess_third_party, precision: 12, scale: 2
      t.string  :hire_purchase_company
      t.string  :agent
      t.string  :holder
      t.decimal :premium, precision: 12, scale: 2       # before GST
      t.decimal :gst, precision: 12, scale: 2
      t.decimal :total, precision: 12, scale: 2
      t.string  :debit_note_number
      t.date    :debit_note_date
      t.date    :paid_on
      t.datetime :renewed_at
      t.timestamps
    end
    add_index :vehicle_insurance_policies, :vehicle_id, unique: true, where: "current",
              name: "index_vehicle_insurance_policies_one_current"
    add_index :vehicle_insurance_policies, %i[company_id ends_on]

    # Up to 5 files per policy: policy schedule, Certificate of Insurance, premium debit note.
    create_table :vehicle_insurance_documents do |t|
      t.references :company, null: false, foreign_key: true
      t.references :vehicle_insurance_policy, null: false, foreign_key: true
      t.string :file, null: false                     # CarrierWave (DocumentUploader)
      t.string :kind, null: false, default: "other"   # policy | certificate | invoice | other
      t.string :plate_on_document
      t.boolean :plate_differs, null: false, default: false # warning only
      t.timestamps
    end
  end
end
