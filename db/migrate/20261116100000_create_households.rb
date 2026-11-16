# Convoy App Household (platform-wide, no company): a family with its postal address, the adults in it (an account, or a
# mobile that was invited and has no account yet), the Quick Invite links, the children (dependants) and which adults may
# receive each child. Companies get their own copy of a family when a bus request is accepted (a later phase).
class CreateHouseholds < ActiveRecord::Migration[8.1]
  def change
    create_table :households do |t|
      t.string :name, null: false
      t.string :postal, null: false
      t.string :block, null: false
      t.string :street, null: false
      t.string :floor
      t.string :unit
      t.string :line2
      t.decimal :lat, precision: 10, scale: 7
      t.decimal :lng, precision: 10, scale: 7
      t.boolean :billing_same, null: false, default: true
      t.text :billing_address
      t.references :created_by, foreign_key: { to_table: :app_accounts, on_delete: :nullify }
      t.datetime :discarded_at, index: true
      t.timestamps
      t.check_constraint "billing_same OR billing_address IS NOT NULL", name: "households_billing_address"
    end

    create_table :household_members do |t|
      t.references :household, null: false, foreign_key: { on_delete: :cascade }
      t.references :app_account, foreign_key: { on_delete: :cascade }
      t.string :invite_phone
      t.string :invite_name
      t.string :status, null: false, default: "invited"
      t.string :relationship
      t.boolean :admin, null: false, default: false
      t.boolean :billing_contact, null: false, default: false
      t.string :photo
      t.references :invited_by, foreign_key: { to_table: :app_accounts, on_delete: :nullify }
      t.string :invited_via, null: false
      t.datetime :joined_at
      t.timestamps
      t.index %i[household_id app_account_id], unique: true, where: "app_account_id IS NOT NULL AND status IN ('invited', 'requested', 'active')",
                                               name: "index_household_members_one_per_account"
      t.index :app_account_id, unique: true, where: "status = 'active'", name: "index_household_members_one_family_per_account", if_not_exists: true
      t.index %i[household_id invite_phone], unique: true, where: "invite_phone IS NOT NULL AND status = 'invited'",
                                             name: "index_household_members_one_invite_per_phone"
      t.index :invite_phone, where: "status = 'invited'", name: "index_household_members_invited_phone"
      t.index :household_id, unique: true, where: "admin", name: "index_household_members_one_admin"
      t.index :household_id, unique: true, where: "billing_contact", name: "index_household_members_one_billing_contact"
      t.check_constraint "status IN ('invited', 'requested', 'active', 'declined')", name: "household_members_status"
      t.check_constraint "invited_via IN ('creator', 'quick', 'manual')", name: "household_members_invited_via"
      t.check_constraint "app_account_id IS NOT NULL OR invite_phone IS NOT NULL", name: "household_members_who"
      t.check_constraint "relationship IS NULL OR relationship IN ('Mother', 'Father', 'Grandparent', 'Relative', 'Domestic Helper', 'Family Friend')",
                         name: "household_members_relationship"
    end

    create_table :household_invite_links do |t|
      t.references :household, null: false, foreign_key: { on_delete: :cascade }
      t.string :token, null: false, index: { unique: true }
      t.references :created_by, foreign_key: { to_table: :app_accounts, on_delete: :nullify }
      t.datetime :expires_at, null: false
      t.timestamps
    end

    create_table :dependants do |t|
      t.references :household, null: false, foreign_key: { on_delete: :cascade }
      t.string :name, null: false
      t.date :birth_date, null: false
      t.references :school, foreign_key: { on_delete: :nullify }
      t.string :school_name, null: false
      t.string :level, null: false
      t.string :gender
      t.string :student_id
      t.string :photo
      t.string :medical_tags, array: true, null: false, default: []
      t.text :medical_note
      t.datetime :discarded_at
      t.timestamps
      t.index :household_id, where: "discarded_at IS NULL", name: "index_dependants_live_on_household_id"
      t.check_constraint "gender IS NULL OR gender IN ('girl', 'boy')", name: "dependants_gender"
    end

    create_table :dependant_guardians do |t|
      t.references :dependant, null: false, foreign_key: { on_delete: :cascade }
      t.references :household_member, null: false, foreign_key: { on_delete: :cascade }
      t.timestamps
      t.index %i[dependant_id household_member_id], unique: true, name: "index_dependant_guardians_unique"
    end
  end
end
