# A link the company gives its drivers (Convoy Driver app › Account › Company Links): depot map, leave form, incident
# form… Seeded for now; the Convoy OS screen to manage them comes later.
# == Schema Information
#
# Table name: company_links
# Database name: primary
#
#  id         :bigint           not null, primary key
#  note       :string
#  position   :integer          default(0), not null
#  title      :string           not null
#  url        :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  company_id :bigint           not null
#
# Indexes
#
#  index_company_links_on_company_id  (company_id)
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#
class CompanyLink < ApplicationRecord
  include TenantScoped
  audited

  validates :title, :url, presence: true
  validates :url, format: { with: %r{\Ahttps?://\S+\z}i, message: "must start with http:// or https://" }

  default_scope { order(:position, :id) }
end
