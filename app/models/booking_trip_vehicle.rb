# Vehicles a booking trip asks for: a type and how many.
# == Schema Information
#
# Table name: booking_trip_vehicles
# Database name: primary
#
#  id              :bigint           not null, primary key
#  count           :integer          default(1), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  booking_trip_id :bigint           not null
#  company_id      :bigint           not null
#  vehicle_type_id :bigint           not null
#
# Indexes
#
#  idx_on_booking_trip_id_vehicle_type_id_ca7b84be82  (booking_trip_id,vehicle_type_id) UNIQUE
#  index_booking_trip_vehicles_on_company_id          (company_id)
#  index_booking_trip_vehicles_on_vehicle_type_id     (vehicle_type_id)
#
# Foreign Keys
#
#  fk_rails_...  (booking_trip_id => booking_trips.id)
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (vehicle_type_id => vehicle_types.id)
#
class BookingTripVehicle < ApplicationRecord
  include TenantScoped

  belongs_to :trip, class_name: "BookingTrip", foreign_key: :booking_trip_id, inverse_of: :vehicles
  belongs_to :vehicle_type

  validates :count, numericality: { only_integer: true, greater_than: 0 }
end
