# == Schema Information
#
# Table name: trip_vehicle_slots
# Database name: primary
#
#  id         :bigint           not null, primary key
#  price      :decimal(12, 2)
#  slot_no    :integer          not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  company_id :bigint           not null
#  trip_id    :bigint           not null
#  vehicle_id :bigint
#
# Indexes
#
#  index_trip_vehicle_slots_on_company_id  (company_id)
#  index_trip_vehicle_slots_on_trip_id     (trip_id)
#  index_trip_vehicle_slots_on_vehicle     (vehicle_id)
#  index_trip_vehicle_slots_on_vehicle_id  (vehicle_id)
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (trip_id => trips.id)
#  fk_rails_...  (vehicle_id => vehicles.id)
#
# Vehicle slot n of a trip: its planned bus (empty = unassigned) and its own client price when prices are set each.
class TripVehicleSlot < ApplicationRecord
  include TenantScoped
  audited associated_with: :trip

  belongs_to :trip, inverse_of: :vehicle_slots
  belongs_to :vehicle, optional: true

  validates :slot_no, numericality: { only_integer: true, greater_than: 0 }
  validates :price, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
end
