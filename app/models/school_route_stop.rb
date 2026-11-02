# == Schema Information
#
# Table name: school_route_stops
# Database name: primary
#
#  id              :bigint           not null, primary key
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
#
# Indexes
#
#  index_school_route_stops_on_company_id       (company_id)
#  index_school_route_stops_on_school_route_id  (school_route_id)
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (school_route_id => school_routes.id)
#
class SchoolRouteStop < ApplicationRecord
  include TenantScoped
  include MinuteTime

  belongs_to :route, class_name: "SchoolRoute", foreign_key: :school_route_id, inverse_of: :stops

  minute_time :scheduled_time
end
