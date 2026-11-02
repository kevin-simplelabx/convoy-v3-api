# Client Portal sign-in. portal_jwts: one row per sign-in (Bearer token allowlist, like allowlisted_jwts for Convoy OS),
# with the client account picked for it (a person can be a user of several clients). portal_sign_in_codes: the 6-digit
# one-time codes sent by email at first sign-in (set a password) or for a forgotten password; only a digest is kept.
class CreatePortalSignIn < ActiveRecord::Migration[8.1]
  def change
    create_table :portal_jwts do |t|
      t.references :portal_account, null: false, foreign_key: true
      t.references :client_user, foreign_key: true
      t.string :jti, null: false, index: { unique: true }
      t.string :aud
      t.datetime :exp, null: false, index: true
      t.string :name
      t.datetime :last_used_at
      t.timestamps
    end

    create_table :portal_sign_in_codes do |t|
      t.references :portal_account, null: false, foreign_key: true, index: false
      t.string :purpose, null: false
      t.string :code_digest, null: false
      t.datetime :expires_at, null: false
      t.integer :attempts, null: false, default: 0
      t.datetime :used_at
      t.string :ip
      t.timestamps
    end
    add_index :portal_sign_in_codes, %i[portal_account_id created_at]
    add_check_constraint :portal_sign_in_codes, "purpose IN ('first', 'reset')", name: "portal_sign_in_codes_purpose"
  end
end
