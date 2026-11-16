# A client's request to cancel confirmed trips of a booking: the booking (the rest of it), a day, or one trip. Sent from
# the Convoy App (fee quoted then: runs inside the client's late_cancel_hours are charged in full), or recorded in
# Convoy OS on the client's behalf. Accepted: the trips are cancelled (approved ones: their Scheduler runs too, as
# cancelled when it was asked); declined: nothing changes.
# == Schema Information
#
# Table name: booking_cancel_requests
# Database name: primary
#
#  id                          :bigint           not null, primary key
#  fee_quoted                  :decimal(12, 2)   default(0.0), not null
#  note                        :text
#  reason                      :text
#  requested_at                :datetime         not null
#  requested_by_name           :string           not null
#  resolution_note             :text
#  resolved_at                 :datetime
#  scope                       :string           default("booking"), not null
#  status                      :string           default("open"), not null
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#  booking_day_id              :bigint
#  booking_id                  :bigint           not null
#  booking_trip_id             :bigint
#  company_id                  :bigint           not null
#  requested_by_app_account_id :bigint
#  requested_by_client_user_id :bigint
#  requested_by_id             :bigint
#  resolved_by_id              :bigint
#
# Indexes
#
#  index_booking_cancel_requests_on_booking_day_id               (booking_day_id)
#  index_booking_cancel_requests_on_booking_id                   (booking_id)
#  index_booking_cancel_requests_on_booking_trip_id              (booking_trip_id)
#  index_booking_cancel_requests_on_company_id                   (company_id)
#  index_booking_cancel_requests_on_company_id_and_status        (company_id,status)
#  index_booking_cancel_requests_on_requested_by_app_account_id  (requested_by_app_account_id)
#  index_booking_cancel_requests_on_requested_by_client_user_id  (requested_by_client_user_id)
#  index_booking_cancel_requests_on_requested_by_id              (requested_by_id)
#  index_booking_cancel_requests_on_resolved_by_id               (resolved_by_id)
#
# Foreign Keys
#
#  fk_rails_...  (booking_day_id => booking_days.id)
#  fk_rails_...  (booking_id => bookings.id)
#  fk_rails_...  (booking_trip_id => booking_trips.id)
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (requested_by_app_account_id => app_accounts.id) ON DELETE => nullify
#  fk_rails_...  (requested_by_client_user_id => client_users.id)
#  fk_rails_...  (requested_by_id => users.id)
#  fk_rails_...  (resolved_by_id => users.id)
#
class BookingCancelRequest < ApplicationRecord
  include TenantScoped
  audited associated_with: :booking

  belongs_to :booking, inverse_of: :cancel_requests
  belongs_to :booking_trip, optional: true
  belongs_to :booking_day, optional: true
  belongs_to :resolved_by, class_name: "User", optional: true
  include ActorStamp
  actor_stamp :requested, app_account: true

  enum :status, { open: "open", accepted: "accepted", declined: "declined" }, validate: true
  enum :scope, { booking: "booking", day: "day", trip: "trip" }, prefix: :for, validate: true

  REASONS = [ "Trip postponed", "Trip called off", "Booked by mistake", "Booking again with changes", "Other reason" ].freeze

  validates :requested_by_name, :requested_at, presence: true
  validates :booking_trip, presence: true, if: :for_trip?
  validates :booking_day, presence: true, if: :for_day?

  # The trips it asks to cancel: the trip, the day's trips, or every trip of the booking.
  def trips
    if for_trip? then [ booking_trip ]
    elsif for_day? then booking.trips.select { it.booking_day_id == booking_day_id }
    else booking.trips.to_a
    end
  end
end
