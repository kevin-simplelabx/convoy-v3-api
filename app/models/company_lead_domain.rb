# Convoy's follow-up of the people who asked from one work email domain: status and a note.
# == Schema Information
#
# Table name: company_lead_domains
# Database name: primary
#
#  id            :bigint           not null, primary key
#  domain        :string           not null
#  note          :text
#  status        :string           default("new"), not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  updated_by_id :bigint
#
# Indexes
#
#  index_company_lead_domains_on_domain         (domain) UNIQUE
#  index_company_lead_domains_on_updated_by_id  (updated_by_id)
#
# Foreign Keys
#
#  fk_rails_...  (updated_by_id => users.id)
#
class CompanyLeadDomain < ApplicationRecord
  audited

  STATUSES = { "new" => "New", "contacted" => "Contacted", "demo" => "Demo Booked", "signed" => "Signed Up", "lost" => "Not Interested" }.freeze

  belongs_to :updated_by, class_name: "User", optional: true

  validates :status, inclusion: { in: STATUSES.keys }
end
