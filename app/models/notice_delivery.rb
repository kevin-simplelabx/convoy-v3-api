# == Schema Information
#
# Table name: notice_deliveries
# Database name: primary
#
#  id         :bigint           not null, primary key
#  channel    :string           not null
#  recipients :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  company_id :bigint           not null
#  notice_id  :bigint           not null
#
# Indexes
#
#  index_notice_deliveries_on_company_id  (company_id)
#  index_notice_deliveries_on_notice_id   (notice_id)
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (notice_id => notices.id)
#
# A push or SMS send of a notice (recorded only).
class NoticeDelivery < ApplicationRecord
  include TenantScoped

  belongs_to :notice

  validates :channel, inclusion: { in: %w[push sms] }
end
