# Someone in the Convoy App who asked their company to use Convoy (Organisations > Suggest Convoy).
# == Schema Information
#
# Table name: company_leads
# Database name: primary
#
#  id           :bigint           not null, primary key
#  asked_at     :datetime         not null
#  company_name :string           not null
#  contact      :string
#  domain       :string           not null
#  named_name   :string
#  named_via    :string
#  source       :string           default("Convoy app"), not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
# Indexes
#
#  index_company_leads_on_domain_and_asked_at  (domain,asked_at)
#
class CompanyLead < ApplicationRecord
  normalizes :domain, with: ->(v) { v.to_s.strip.downcase.delete_prefix("@") }

  validates :domain, :company_name, :asked_at, presence: true
end
