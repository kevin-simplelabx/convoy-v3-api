# Convoy App Phase 3: staff who ride a client's shuttle. A row is an invitation made when a verified work email matched
# the client's domain; the person taps Accept / Not Me in the app and the office can remove the link (never auto-linked).
class CreateClientRiders < ActiveRecord::Migration[8.1]
  def change
    create_table :client_riders do |t|
      t.references :company, null: false, foreign_key: true
      t.references :client, null: false, foreign_key: true
      t.references :app_account, null: false, foreign_key: { on_delete: :cascade }
      t.string :matched_email, null: false
      t.string :status, null: false, default: "invited"
      t.datetime :responded_at
      t.references :removed_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.timestamps
      t.index %i[client_id app_account_id], unique: true
      t.check_constraint "status IN ('invited', 'accepted', 'declined', 'removed')", name: "client_riders_status"
    end
  end
end
