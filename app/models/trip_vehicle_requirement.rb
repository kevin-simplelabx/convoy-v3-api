# == Schema Information
#
# Table name: trip_vehicle_requirements
# Database name: primary
#
#  id              :bigint           not null, primary key
#  count           :integer          default(1), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  company_id      :bigint           not null
#  trip_id         :bigint           not null
#  vehicle_type_id :bigint           not null
#
# Indexes
#
#  index_trip_vehicle_requirements_on_company_id                   (company_id)
#  index_trip_vehicle_requirements_on_trip_id                      (trip_id)
#  index_trip_vehicle_requirements_on_trip_id_and_vehicle_type_id  (trip_id,vehicle_type_id) UNIQUE
#  index_trip_vehicle_requirements_on_vehicle_type_id              (vehicle_type_id)
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (trip_id => trips.id)
#  fk_rails_...  (vehicle_type_id => vehicle_types.id)
#
# Vehicles required: a type and how many (2 x 23-seater).
class TripVehicleRequirement < ApplicationRecord
  include TenantScoped
  audited associated_with: :trip

  belongs_to :trip, inverse_of: :vehicle_requirements
  belongs_to :vehicle_type

  validates :count, numericality: { only_integer: true, greater_than: 0 }
  validates :vehicle_type_id, uniqueness: { scope: :trip_id }

  def label = "#{count} x #{vehicle_type.seats}-seater"
end
