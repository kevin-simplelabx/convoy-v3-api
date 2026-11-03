# == Schema Information
#
# Table name: school_route_stops
# Database name: primary
#
#  id              :bigint           not null, primary key
#  dwell_seconds   :integer
#  lat             :decimal(10, 7)
#  lng             :decimal(10, 7)
#  name            :string           not null
#  position        :integer          not null
#  riders_count    :integer          default(0), not null
#  scheduled_time  :integer
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  company_id      :bigint           not null
#  school_route_id :bigint           not null
#  stop_id         :bigint
#  stop_point_id   :bigint
#
# Indexes
#
#  index_school_route_stops_on_company_id       (company_id)
#  index_school_route_stops_on_school_route_id  (school_route_id)
#  index_school_route_stops_on_stop_id          (stop_id)
#  index_school_route_stops_on_stop_point_id    (stop_point_id)
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (school_route_id => school_routes.id)
#  fk_rails_...  (stop_id => stops.id)
#  fk_rails_...  (stop_point_id => stop_points.id)
#
class SchoolRouteStop < ApplicationRecord
  include TenantScoped
  include MinuteTime

  belongs_to :route, class_name: "SchoolRoute", foreign_key: :school_route_id, inverse_of: :stops
  belongs_to :stop, optional: true
  belongs_to :stop_point, optional: true
  has_many :riders, class_name: "SchoolRouteRider", foreign_key: :school_route_stop_id, dependent: :delete_all, inverse_of: :stop

  minute_time :scheduled_time
end
