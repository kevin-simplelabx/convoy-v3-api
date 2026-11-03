# A rider (school rider id) picked up / dropped off at a stop of a route plan.
# == Schema Information
#
# Table name: school_route_riders
# Database name: primary
#
#  id                   :bigint           not null, primary key
#  rid                  :string           not null
#  company_id           :bigint           not null
#  school_route_id      :bigint           not null
#  school_route_stop_id :bigint           not null
#
# Indexes
#
#  index_school_route_riders_on_rid                   (rid)
#  index_school_route_riders_on_school_route_id       (school_route_id)
#  index_school_route_riders_on_school_route_stop_id  (school_route_stop_id)
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (school_route_id => school_routes.id) ON DELETE => cascade
#  fk_rails_...  (school_route_stop_id => school_route_stops.id) ON DELETE => cascade
#
class SchoolRouteRider < ApplicationRecord
  include TenantScoped

  belongs_to :school_route
  belongs_to :stop, class_name: "SchoolRouteStop", foreign_key: :school_route_stop_id, inverse_of: :riders
end
