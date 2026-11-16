# Convoy App › Bookings (Phase 7), columns on existing tables (indexes concurrently, FKs and checks validated next).
# companies.accepts_personal_bookings: the company takes Personal bookings from the app (an Individual client per person).
# clients.app_account_id: the person an Individual client was made for (one per company); Individual names need not be unique.
# bookings: title, payer (client = billed to the client; self = paid in the app), Bill To fund, the app account that booked,
#   the client-user link a Pay Myself booking was made from, Book Again source, charter terms accepted, receipt in a company's name.
# booking_trips.adults: of the passengers, how many are teachers / adults (pax stays the total).
# booking_cancel_requests: scope booking | day | trip, the day, a note beside the reason, the charge quoted when sent, the app account.
# client_pickup_points.created_by_client_user_id: a booking admin saved it from the app.
# finance_settings: how Personal bookings are paid (card with a fee in %, PayNow).
# user_notification_preferences: two new bell kinds (change_reply, client_cancelled).
class AddAppBookingsColumns < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_column :companies, :accepts_personal_bookings, :boolean, null: false, default: false

    add_column :clients, :app_account_id, :bigint
    add_index :clients, %i[company_id app_account_id], unique: true, where: "app_account_id IS NOT NULL AND discarded_at IS NULL",
                                                       name: "index_clients_one_individual_per_account", algorithm: :concurrently
    add_index :clients, :app_account_id, algorithm: :concurrently
    add_foreign_key :clients, :app_accounts, on_delete: :nullify, validate: false
    add_index :clients, %i[company_id name], unique: true, where: "discarded_at IS NULL AND kind <> 'individual'",
                                             name: "index_clients_on_company_id_and_name_not_individual", algorithm: :concurrently
    remove_index :clients, %i[company_id name], unique: true, where: "(discarded_at IS NULL)", name: "index_clients_on_company_id_and_name",
                                                algorithm: :concurrently

    add_column :bookings, :title, :string
    add_column :bookings, :payer, :string, null: false, default: "client"
    add_column :bookings, :client_bill_fund_id, :bigint
    add_column :bookings, :created_by_app_account_id, :bigint
    add_column :bookings, :booked_via_client_user_id, :bigint
    add_column :bookings, :copied_from_booking_id, :bigint
    add_column :bookings, :terms_accepted_at, :datetime
    add_column :bookings, :receipt_name, :string
    add_column :bookings, :receipt_uen, :string
    add_column :bookings, :receipt_address, :text
    add_index :bookings, :client_bill_fund_id, algorithm: :concurrently
    add_index :bookings, :created_by_app_account_id, algorithm: :concurrently
    add_index :bookings, :booked_via_client_user_id, algorithm: :concurrently
    add_index :bookings, :copied_from_booking_id, algorithm: :concurrently
    add_foreign_key :bookings, :client_bill_funds, validate: false
    add_foreign_key :bookings, :app_accounts, column: :created_by_app_account_id, on_delete: :nullify, validate: false
    add_foreign_key :bookings, :client_users, column: :booked_via_client_user_id, validate: false
    add_foreign_key :bookings, :bookings, column: :copied_from_booking_id, on_delete: :nullify, validate: false
    add_check_constraint :bookings, "payer IN ('client', 'self')", name: "bookings_payer", validate: false
    remove_check_constraint :bookings, "num_nonnulls(created_by_id, created_by_client_user_id) <= 1", name: "bookings_created_by_one"
    add_check_constraint :bookings, "num_nonnulls(created_by_id, created_by_client_user_id, created_by_app_account_id) <= 1",
                         name: "bookings_created_by_one", validate: false

    add_column :booking_trips, :adults, :integer, null: false, default: 0

    add_column :booking_cancel_requests, :scope, :string, null: false, default: "booking"
    add_column :booking_cancel_requests, :booking_day_id, :bigint
    add_column :booking_cancel_requests, :note, :text
    add_column :booking_cancel_requests, :fee_quoted, :decimal, precision: 12, scale: 2, null: false, default: 0
    add_column :booking_cancel_requests, :requested_by_app_account_id, :bigint
    add_index :booking_cancel_requests, :booking_day_id, algorithm: :concurrently
    add_index :booking_cancel_requests, :requested_by_app_account_id, algorithm: :concurrently
    add_foreign_key :booking_cancel_requests, :booking_days, validate: false
    add_foreign_key :booking_cancel_requests, :app_accounts, column: :requested_by_app_account_id, on_delete: :nullify, validate: false
    remove_check_constraint :booking_cancel_requests, "num_nonnulls(requested_by_id, requested_by_client_user_id) <= 1",
                            name: "booking_cancel_requests_requested_by_one"
    add_check_constraint :booking_cancel_requests, "num_nonnulls(requested_by_id, requested_by_client_user_id, requested_by_app_account_id) <= 1",
                         name: "booking_cancel_requests_requested_by_one", validate: false

    add_column :client_pickup_points, :created_by_client_user_id, :bigint
    add_index :client_pickup_points, :created_by_client_user_id, algorithm: :concurrently
    add_foreign_key :client_pickup_points, :client_users, column: :created_by_client_user_id, on_delete: :nullify, validate: false

    add_column :finance_settings, :booking_card_on, :boolean, null: false, default: true
    add_column :finance_settings, :booking_card_fee_pct, :decimal, precision: 5, scale: 2, null: false, default: 3.7
    add_column :finance_settings, :booking_paynow_on, :boolean, null: false, default: true

    add_column :user_notification_preferences, :change_reply, :boolean, null: false, default: true
    add_column :user_notification_preferences, :client_cancelled, :boolean, null: false, default: true
  end
end
