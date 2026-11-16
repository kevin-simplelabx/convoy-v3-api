# Convoy App › Bookings (Phase 7), new tables.
# client_bill_funds: the funds a school / company bills a booking to (Bill To: Admin Fund, CCA Fund ...), per client.
# booking_change_replies: Can't Accept on changes the transport company made (reason + message), by a client user or an app account.
# booking_payments: money of a prepaid (Personal / Pay Myself) booking, simulated: one payment at submit, refunds after.
# app_saved_points: My Points of an app account (platform-level, every booking account of the person).
class CreateAppBookings < ActiveRecord::Migration[8.1]
  def change
    create_table :client_bill_funds do |t|
      t.references :company, null: false, foreign_key: true
      t.references :client, null: false, foreign_key: true
      t.string :name, null: false
      t.integer :position, null: false, default: 0
      t.datetime :discarded_at
      t.timestamps
    end
    add_index :client_bill_funds, "client_id, lower(name)", unique: true, where: "discarded_at IS NULL", name: "index_client_bill_funds_on_client_and_name"

    create_table :booking_change_replies do |t|
      t.references :company, null: false, foreign_key: true
      t.references :booking, null: false, foreign_key: true
      t.string :reason, null: false
      t.text :message
      t.string :replied_by_name, null: false
      t.references :replied_by_client_user, foreign_key: { to_table: :client_users }
      t.references :replied_by_app_account, foreign_key: { to_table: :app_accounts, on_delete: :nullify }
      t.timestamps
    end
    add_check_constraint :booking_change_replies, "num_nonnulls(replied_by_client_user_id, replied_by_app_account_id) <= 1", name: "booking_change_replies_by_one"

    create_table :booking_payments do |t|
      t.references :company, null: false, foreign_key: true
      t.references :booking, null: false, foreign_key: true
      t.string :kind, null: false
      t.string :method, null: false
      t.string :method_label, null: false
      t.decimal :amount, precision: 12, scale: 2, null: false
      t.decimal :card_fee, precision: 12, scale: 2, null: false, default: 0
      t.string :reference, null: false
      t.datetime :paid_at, null: false
      t.text :note
      t.timestamps
    end
    add_check_constraint :booking_payments, "kind IN ('payment', 'refund')", name: "booking_payments_kind"
    add_check_constraint :booking_payments, "method IN ('card', 'paynow')", name: "booking_payments_method"
    add_index :booking_payments, %i[booking_id kind], unique: true, where: "kind = 'payment'", name: "index_booking_payments_one_payment"

    create_table :app_saved_points do |t|
      t.references :app_account, null: false, foreign_key: { on_delete: :cascade }
      t.string :name, null: false
      t.string :address
      t.decimal :lat, precision: 10, scale: 7
      t.decimal :lng, precision: 10, scale: 7
      t.text :note
      t.timestamps
    end
    add_index :app_saved_points, "app_account_id, lower(name)", unique: true, name: "index_app_saved_points_on_account_and_name"
  end
end
