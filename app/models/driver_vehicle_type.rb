# HR > Drivers > Vehicle Types: the vehicle type whose rates a driver is paid at from a date.
# == Schema Information
#
# Table name: driver_vehicle_types
# Database name: primary
#
#  id              :bigint           not null, primary key
#  ends_on         :date
#  starts_on       :date             not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  company_id      :bigint           not null
#  driver_id       :bigint           not null
#  vehicle_type_id :bigint           not null
#
# Indexes
#
#  index_driver_vehicle_types_on_company_id               (company_id)
#  index_driver_vehicle_types_on_driver_id_and_starts_on  (driver_id,starts_on) UNIQUE
#  index_driver_vehicle_types_on_vehicle_type_id          (vehicle_type_id)
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (driver_id => drivers.id)
#  fk_rails_...  (vehicle_type_id => vehicle_types.id)
#
class DriverVehicleType < ApplicationRecord
  include DatedAssignment

  belongs_to :vehicle_type
end
