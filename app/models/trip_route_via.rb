# == Schema Information
#
# Table name: trip_route_vias
# Database name: primary
#
#  id            :bigint           not null, primary key
#  direction     :integer          default(1), not null
#  from_position :integer          not null
#  lat           :decimal(10, 7)   not null
#  lng           :decimal(10, 7)   not null
#  position      :integer          not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  company_id    :bigint           not null
#  trip_id       :bigint           not null
#
# Indexes
#
#  index_trip_route_vias_on_company_id  (company_id)
#  index_trip_route_vias_on_trip_id     (trip_id)
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (trip_id => trips.id)
#
# A pin dragged onto the road between the stop at from_position and the next one.
class TripRouteVia < ApplicationRecord
  include TenantScoped
  audited associated_with: :trip

  belongs_to :trip, inverse_of: :route_vias

  validates :lat, presence: true, numericality: { in: -90..90 }
  validates :lng, presence: true, numericality: { in: -180..180 }
  validates :from_position, :position, presence: true
end
