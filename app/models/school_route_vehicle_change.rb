# == Schema Information
#
# Table name: school_route_vehicle_changes
# Database name: primary
#
#  id              :bigint           not null, primary key
#  effective_from  :date             not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  company_id      :bigint           not null
#  created_by_id   :bigint
#  school_route_id :bigint           not null
#  vehicle_id      :bigint
#
# Indexes
#
#  index_route_vehicle_changes_once                       (school_route_id,effective_from) UNIQUE
#  index_school_route_vehicle_changes_on_company_id       (company_id)
#  index_school_route_vehicle_changes_on_created_by_id    (created_by_id)
#  index_school_route_vehicle_changes_on_school_route_id  (school_route_id)
#  index_school_route_vehicle_changes_on_vehicle_id       (vehicle_id)
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (created_by_id => users.id)
#  fk_rails_...  (school_route_id => school_routes.id)
#  fk_rails_...  (vehicle_id => vehicles.id)
#
# The regular bus of a route from a date (Permanent change from this date / Make it the regular bus).
class SchoolRouteVehicleChange < ApplicationRecord
  include TenantScoped
  audited associated_with: :route

  belongs_to :route, class_name: "SchoolRoute", foreign_key: :school_route_id, inverse_of: :vehicle_changes
  belongs_to :vehicle, optional: true
  belongs_to :created_by, class_name: "User", optional: true

  validates :effective_from, presence: true, uniqueness: { scope: :school_route_id }
end
