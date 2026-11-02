class DeviseCreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      ## Database authenticatable
      t.string :email,              null: false, default: ""
      t.string :encrypted_password, null: false, default: ""

      ## Recoverable
      t.string   :reset_password_token
      t.datetime :reset_password_sent_at

      ## Rememberable
      t.datetime :remember_created_at

      t.references :company, foreign_key: true          # null for Convoy Admin (platform)
      t.string  :name, null: false
      t.string  :mobile
      t.string  :avatar                                  # CarrierWave (ImageUploader)
      t.string  :role, null: false, default: "member"    # convoy_admin | admin | member
      t.boolean :owner, null: false, default: false      # the company's Super Admin
      t.string  :permissions, array: true, null: false, default: []
      t.string  :status, null: false, default: "active"  # active | suspended
      t.datetime :last_seen_at
      t.timestamps
    end

    add_index :users, :email, unique: true
    add_index :users, :reset_password_token, unique: true
    add_index :users, :permissions, using: :gin
  end
end
