# Where an accepted request's child goes on one session (Route Fit: the same block's stop or a new stop on a route),
# so the seat is held until the route plan has the child.
# == Schema Information
#
# Table name: bus_request_places
# Database name: primary
#
#  id              :bigint           not null, primary key
#  delta_minutes   :decimal(5, 1)
#  kind            :string           not null
#  route_label     :string
#  session         :string           not null
#  stop_name       :string
#  bus_request_id  :bigint           not null
#  school_route_id :bigint
#
# Indexes
#
#  index_bus_request_places_on_bus_request_id_and_session  (bus_request_id,session) UNIQUE
#  index_bus_request_places_on_school_route_id             (school_route_id)
#
# Foreign Keys
#
#  fk_rails_...  (bus_request_id => bus_requests.id) ON DELETE => cascade
#  fk_rails_...  (school_route_id => school_routes.id) ON DELETE => nullify
#
class BusRequestPlace < ApplicationRecord
  belongs_to :bus_request, inverse_of: :places
  belongs_to :school_route, optional: true

  validates :session, inclusion: { in: %w[AM PM] }
  validates :kind, inclusion: { in: %w[fits new] }
end
