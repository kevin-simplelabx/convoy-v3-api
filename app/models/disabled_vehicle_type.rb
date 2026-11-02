# == Schema Information
#
# Table name: disabled_vehicle_types
# Database name: primary
#
#  id              :bigint           not null, primary key
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  company_id      :bigint           not null
#  vehicle_type_id :bigint           not null
#
# Indexes
#
#  index_disabled_vehicle_types_on_company_id                      (company_id)
#  index_disabled_vehicle_types_on_company_id_and_vehicle_type_id  (company_id,vehicle_type_id) UNIQUE
#  index_disabled_vehicle_types_on_vehicle_type_id                 (vehicle_type_id)
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (vehicle_type_id => vehicle_types.id)
#
# A platform vehicle type the company turned off (hidden from its trip forms).
class DisabledVehicleType < ApplicationRecord
  include TenantScoped
  audited

  belongs_to :vehicle_type

  validates :vehicle_type_id, uniqueness: { scope: :company_id }
end
