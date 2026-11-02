# == Schema Information
#
# Table name: notice_routes
# Database name: primary
#
#  id              :bigint           not null, primary key
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  company_id      :bigint           not null
#  notice_id       :bigint           not null
#  school_route_id :bigint           not null
#
# Indexes
#
#  index_notice_routes_on_company_id       (company_id)
#  index_notice_routes_on_notice_id        (notice_id)
#  index_notice_routes_on_school_route_id  (school_route_id)
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (notice_id => notices.id)
#  fk_rails_...  (school_route_id => school_routes.id)
#
class NoticeRoute < ApplicationRecord
  include TenantScoped

  belongs_to :notice, inverse_of: :route_targets
  belongs_to :school_route
end
