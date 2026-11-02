# One row per sign-in (devise-jwt Allowlist): a Bearer token works while its jti is here and not expired.
# name = device / app, company_id = the company a Convoy Admin picked for this sign-in, last_used_at for the device list.
class CreateAllowlistedJwts < ActiveRecord::Migration[8.1]
  def change
    create_table :allowlisted_jwts do |t|
      t.references :user, null: false, foreign_key: true
      t.references :company, foreign_key: true
      t.string :jti, null: false, index: { unique: true }
      t.string :aud
      t.datetime :exp, null: false, index: true
      t.string :name
      t.datetime :last_used_at
      t.timestamps
    end
  end
end
