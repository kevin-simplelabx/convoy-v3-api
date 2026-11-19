# Driver app / Convoy App WebSocket (19/11/2026): a one-time ticket to open /cable. The app asks for it with its Bearer
# token and puts it in the socket URL, so the long-lived JWT never sits in a URL or a proxy log. Valid 60 s, used once;
# goes with its sign-in (cascade).
class CreateCableTickets < ActiveRecord::Migration[8.1]
  def change
    create_table :cable_tickets do |t|
      t.string :token_digest, null: false, index: { unique: true }
      t.references :driver_jwt, foreign_key: { on_delete: :cascade }
      t.references :app_jwt, foreign_key: { on_delete: :cascade }
      t.datetime :expires_at, null: false, index: true
      t.datetime :used_at
      t.datetime :created_at, null: false
    end
    add_check_constraint :cable_tickets, "num_nonnulls(driver_jwt_id, app_jwt_id) = 1", name: "cable_tickets_one_sign_in"
  end
end
