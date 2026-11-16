# One trip a cancellation request asks about: exactly what was quoted when it was sent, so accepting it never touches a trip
# that already ran or was under way then.
# == Schema Information
#
# Table name: booking_cancel_request_trips
# Database name: primary
#
#  id                        :bigint           not null, primary key
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  booking_cancel_request_id :bigint           not null
#  booking_trip_id           :bigint           not null
#  company_id                :bigint           not null
#
# Indexes
#
#  index_booking_cancel_request_trips_on_booking_trip_id  (booking_trip_id)
#  index_booking_cancel_request_trips_on_company_id       (company_id)
#  index_booking_cancel_request_trips_unique              (booking_cancel_request_id,booking_trip_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (booking_cancel_request_id => booking_cancel_requests.id) ON DELETE => cascade
#  fk_rails_...  (booking_trip_id => booking_trips.id) ON DELETE => cascade
#  fk_rails_...  (company_id => companies.id)
#
class BookingCancelRequestTrip < ApplicationRecord
  include TenantScoped

  belongs_to :request, class_name: "BookingCancelRequest", foreign_key: :booking_cancel_request_id, inverse_of: :request_trips
  belongs_to :booking_trip
end
