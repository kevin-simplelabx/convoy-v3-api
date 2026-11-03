# Convoy Driver app sign-in: one account per person (mobile number, platform-wide, not per company), the one-time codes
# sent to a mobile, and the Bearer token allowlist with the company membership picked for that sign-in. Own drivers and
# operator drivers (the company's records of that person) point to the account once linked by mobile number.
class CreateDriverAccounts < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    create_table :driver_accounts do |t|
      t.string :phone, null: false
      t.string :name
      t.string :email
      t.string :encrypted_password, null: false, default: ""
      t.datetime :password_set_at
      t.datetime :phone_verified_at
      t.datetime :last_sign_in_at
      t.timestamps
    end
    add_index :driver_accounts, :phone, unique: true
    add_index :driver_accounts, :email, unique: true, where: "email IS NOT NULL"

    create_table :driver_sign_in_codes do |t|
      t.string :phone, null: false
      t.string :code_digest, null: false
      t.datetime :expires_at, null: false
      t.integer :attempts, null: false, default: 0
      t.datetime :used_at
      t.string :ip
      t.timestamps
    end
    add_index :driver_sign_in_codes, %i[phone created_at]

    create_table :driver_jwts do |t|
      t.references :driver_account, null: false, foreign_key: true
      t.string :jti, null: false, index: { unique: true }
      t.string :aud
      t.datetime :exp, null: false, index: true
      t.string :name
      t.datetime :last_used_at
      t.references :driver, foreign_key: { on_delete: :nullify }
      t.references :operator_driver, foreign_key: { on_delete: :nullify }
      t.references :driver_app_session, foreign_key: { on_delete: :nullify }, index: false
      t.timestamps
      t.check_constraint "num_nonnulls(driver_id, operator_driver_id) <= 1", name: "driver_jwts_one_membership"
    end

    add_reference :drivers, :driver_account, index: { algorithm: :concurrently }, foreign_key: { validate: false }
    add_reference :operator_drivers, :driver_account, index: { algorithm: :concurrently }, foreign_key: { validate: false }

    # Employment History: when the driver started (accepted) and left (removed); responded_at is the last answer only.
    %i[drivers operator_drivers].each do |table|
      add_column table, :joined_at, :datetime
      add_column table, :left_at, :datetime
    end
  end
end
