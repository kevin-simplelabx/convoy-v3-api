# Invites sent to own and operator drivers (each send and resend; the SMS is only recorded until a sender is set up),
# and the details a driver shares from the Convoy Driver app (one profile per driver; the app writes it, seeds for now).
# The NRIC / FIN is encrypted (Active Record Encryption); the masked form is kept beside it for lists.
class CreateDriverInvitesAndKyc < ActiveRecord::Migration[8.1]
  def change
    create_table :driver_invites do |t|
      t.references :company, null: false, foreign_key: true
      t.references :invitable, polymorphic: true, null: false
      t.string :kind, null: false, default: "invite"
      t.string :phone, null: false
      t.text :message, null: false
      t.string :delivery, null: false, default: "recorded"
      t.references :sent_by, foreign_key: { to_table: :users }
      t.datetime :created_at, null: false
    end
    add_check_constraint :driver_invites, "kind IN ('invite', 'resend')", name: "driver_invites_kind"

    create_table :driver_kyc_profiles do |t|
      t.references :company, null: false, foreign_key: true
      t.references :driver, polymorphic: true, null: false, index: { unique: true }
      t.string :email
      t.text :address
      t.date :date_of_birth
      t.string :nationality
      t.string :residential_status
      t.string :id_number
      t.string :id_number_masked
      t.string :licence_class
      t.date :licence_qualified_on
      t.string :vocational_licence_number
      t.date :vocational_licence_expires_on
      t.datetime :shared_at
      t.timestamps
    end
    add_index :driver_kyc_profiles, %i[company_id vocational_licence_expires_on]
  end
end
