# == Schema Information
#
# Table name: route_list_version_students
# Database name: primary
#
#  id                         :bigint           not null, primary key
#  class_name                 :string
#  key                        :uuid             not null
#  name                       :string           not null
#  note                       :text
#  parent_name                :string
#  phone                      :string
#  phone2                     :string
#  position                   :integer          default(0), not null
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  company_id                 :bigint           not null
#  route_list_version_stop_id :bigint           not null
#
# Indexes
#
#  idx_on_route_list_version_stop_id_a1ccadebd0     (route_list_version_stop_id)
#  index_route_list_version_students_on_company_id  (company_id)
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (route_list_version_stop_id => route_list_version_stops.id)
#
class RouteListVersionStudent < ApplicationRecord
  include TenantScoped

  belongs_to :stop, class_name: "RouteListVersionStop", foreign_key: :route_list_version_stop_id, inverse_of: :students
end
