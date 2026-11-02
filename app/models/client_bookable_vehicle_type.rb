# Bookable Vehicles: a vehicle type the client can pick in the Client Portal. A client with none can book every type offered.
# == Schema Information
#
# Table name: client_bookable_vehicle_types
# Database name: primary
#
#  id              :bigint           not null, primary key
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  client_id       :bigint           not null
#  company_id      :bigint           not null
#  vehicle_type_id :bigint           not null
#
# Indexes
#
#  idx_on_client_id_vehicle_type_id_9602a14b65             (client_id,vehicle_type_id) UNIQUE
#  index_client_bookable_vehicle_types_on_company_id       (company_id)
#  index_client_bookable_vehicle_types_on_vehicle_type_id  (vehicle_type_id)
#
# Foreign Keys
#
#  fk_rails_...  (client_id => clients.id)
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (vehicle_type_id => vehicle_types.id)
#
class ClientBookableVehicleType < ApplicationRecord
  include TenantScoped
  audited associated_with: :client

  belongs_to :client
  belongs_to :vehicle_type

  validates :vehicle_type_id, uniqueness: { scope: :client_id }
end
