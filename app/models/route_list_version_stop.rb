# == Schema Information
#
# Table name: route_list_version_stops
# Database name: primary
#
#  id                    :bigint           not null, primary key
#  address               :text
#  driver_note           :text
#  name                  :string           not null
#  position              :integer          not null
#  scheduled_time        :integer
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  company_id            :bigint           not null
#  route_list_version_id :bigint           not null
#
# Indexes
#
#  index_route_list_version_stops_on_company_id             (company_id)
#  index_route_list_version_stops_on_route_list_version_id  (route_list_version_id)
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (route_list_version_id => route_list_versions.id)
#
class RouteListVersionStop < ApplicationRecord
  include TenantScoped
  include MinuteTime

  belongs_to :version, class_name: "RouteListVersion", foreign_key: :route_list_version_id, inverse_of: :stops
  has_many :students, -> { order(:position) }, class_name: "RouteListVersionStudent", dependent: :delete_all, inverse_of: :stop

  minute_time :scheduled_time
end
