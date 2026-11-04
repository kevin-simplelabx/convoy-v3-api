# Convoy App sign-in: one account per person (platform-wide, not per company) with every mobile and email the person
# verified (personal or work; any of them signs in), the one-time codes, the Bearer token allowlist (several phones),
# the push tokens of those phones, and the log of mobile numbers that moved to another account (numbers get reissued).
class CreateAppAccounts < ActiveRecord::Migration[8.1]
  def change
    create_table :app_accounts do |t|
      t.string :first_name
      t.string :last_name
      t.string :name_order, null: false, default: "first"
      t.string :photo
      t.boolean :notify_push, null: false, default: true
      t.boolean :notify_sms, null: false, default: false
      t.boolean :notify_email, null: false, default: true
      t.datetime :terms_accepted_at
      t.datetime :last_sign_in_at
      t.datetime :delete_requested_at, index: { where: "delete_requested_at IS NOT NULL" }
      t.timestamps
      t.check_constraint "name_order IN ('first', 'last')", name: "app_accounts_name_order"
    end

    create_table :app_identities do |t|
      t.references :app_account, null: false, foreign_key: { on_delete: :cascade }
      t.string :kind, null: false
      t.string :tag, null: false
      t.string :value, null: false
      t.string :domain
      t.datetime :verified_at, null: false
      t.timestamps
      t.index %i[kind value], unique: true
      t.index %i[app_account_id kind], unique: true, where: "tag = 'personal'", name: "index_app_identities_one_personal"
      t.index %i[app_account_id domain], unique: true, where: "tag = 'work'", name: "index_app_identities_one_work_per_domain"
      t.index :domain, where: "tag = 'work'"
      t.check_constraint "kind IN ('mobile', 'email')", name: "app_identities_kind"
      t.check_constraint "tag IN ('personal', 'work')", name: "app_identities_tag"
      t.check_constraint "kind = 'email' OR tag = 'personal'", name: "app_identities_mobile_personal"
    end

    create_table :app_sign_in_codes do |t|
      t.string :target, null: false
      t.string :purpose, null: false, default: "sign_in"
      t.references :app_account, foreign_key: { on_delete: :cascade }, index: false
      t.string :code_digest, null: false
      t.datetime :expires_at, null: false
      t.integer :attempts, null: false, default: 0
      t.datetime :used_at
      t.string :ip
      t.timestamps
      t.index %i[target created_at]
    end

    create_table :app_jwts do |t|
      t.references :app_account, null: false, foreign_key: { on_delete: :cascade }
      t.string :jti, null: false, index: { unique: true }
      t.string :aud
      t.datetime :exp, null: false, index: true
      t.string :name
      t.datetime :last_used_at
      t.timestamps
    end

    create_table :app_devices do |t|
      t.references :app_account, null: false, foreign_key: { on_delete: :cascade }
      t.references :app_jwt, null: false, foreign_key: { on_delete: :cascade }
      t.string :platform, null: false
      t.string :push_token, null: false, index: { unique: true }
      t.timestamps
      t.check_constraint "platform IN ('ios', 'android')", name: "app_devices_platform"
    end

    create_table :app_identity_moves do |t|
      t.string :kind, null: false
      t.string :value, null: false, index: true
      t.references :from_app_account, foreign_key: { to_table: :app_accounts, on_delete: :nullify }
      t.references :to_app_account, foreign_key: { to_table: :app_accounts, on_delete: :nullify }
      t.datetime :moved_at, null: false
      t.timestamps
    end
  end
end
