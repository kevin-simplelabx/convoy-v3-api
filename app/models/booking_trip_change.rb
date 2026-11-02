# Changes the company made to a booking trip after it was booked ("Pick-up time: 08:00 to 09:00"); the client
# acknowledges them before the trip is approved (or we approve without waiting).
# == Schema Information
#
# Table name: booking_trip_changes
# Database name: primary
#
#  id              :bigint           not null, primary key
#  items           :string           default([]), not null, is an Array
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  booking_trip_id :bigint           not null
#  changed_by_id   :bigint
#  company_id      :bigint           not null
#
# Indexes
#
#  index_booking_trip_changes_on_booking_trip_id  (booking_trip_id)
#  index_booking_trip_changes_on_changed_by_id    (changed_by_id)
#  index_booking_trip_changes_on_company_id       (company_id)
#
# Foreign Keys
#
#  fk_rails_...  (booking_trip_id => booking_trips.id)
#  fk_rails_...  (changed_by_id => users.id)
#  fk_rails_...  (company_id => companies.id)
#
class BookingTripChange < ApplicationRecord
  include TenantScoped

  belongs_to :trip, class_name: "BookingTrip", foreign_key: :booking_trip_id, inverse_of: :changes_made
  belongs_to :changed_by, class_name: "User", optional: true

  validates :items, presence: true
end
