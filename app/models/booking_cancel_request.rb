# A client's request to cancel a booking or one trip of it (from the Client Portal later; recorded here on their behalf).
# Accepted: the trips are cancelled (approved ones: their Scheduler runs too); declined: nothing changes.
# == Schema Information
#
# Table name: booking_cancel_requests
# Database name: primary
#
#  id                          :bigint           not null, primary key
#  reason                      :text
#  requested_at                :datetime         not null
#  requested_by_name           :string           not null
#  resolution_note             :text
#  resolved_at                 :datetime
#  status                      :string           default("open"), not null
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#  booking_id                  :bigint           not null
#  booking_trip_id             :bigint
#  company_id                  :bigint           not null
#  requested_by_client_user_id :bigint
#  requested_by_id             :bigint
#  resolved_by_id              :bigint
#
# Indexes
#
#  index_booking_cancel_requests_on_booking_id                   (booking_id)
#  index_booking_cancel_requests_on_booking_trip_id              (booking_trip_id)
#  index_booking_cancel_requests_on_company_id                   (company_id)
#  index_booking_cancel_requests_on_company_id_and_status        (company_id,status)
#  index_booking_cancel_requests_on_requested_by_client_user_id  (requested_by_client_user_id)
#  index_booking_cancel_requests_on_requested_by_id              (requested_by_id)
#  index_booking_cancel_requests_on_resolved_by_id               (resolved_by_id)
#
# Foreign Keys
#
#  fk_rails_...  (booking_id => bookings.id)
#  fk_rails_...  (booking_trip_id => booking_trips.id)
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (requested_by_client_user_id => client_users.id)
#  fk_rails_...  (requested_by_id => users.id)
#  fk_rails_...  (resolved_by_id => users.id)
#
class BookingCancelRequest < ApplicationRecord
  include TenantScoped
  audited associated_with: :booking

  belongs_to :booking, inverse_of: :cancel_requests
  belongs_to :booking_trip, optional: true
  belongs_to :resolved_by, class_name: "User", optional: true
  include ActorStamp
  actor_stamp :requested

  enum :status, { open: "open", accepted: "accepted", declined: "declined" }, validate: true

  validates :requested_by_name, :requested_at, presence: true
end
