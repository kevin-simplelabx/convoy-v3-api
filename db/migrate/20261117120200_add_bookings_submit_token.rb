# Review fix R6 (17/11/2026): the Convoy App sends a submit_token (one per New Booking form) with Pay / Send for Approval, so
# a double tap or a retry after a timeout returns the booking already made instead of making (and charging) a second one.
class AddBookingsSubmitToken < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_column :bookings, :submit_token, :string
    add_index :bookings, :submit_token, unique: true, where: "submit_token IS NOT NULL", algorithm: :concurrently
  end
end
