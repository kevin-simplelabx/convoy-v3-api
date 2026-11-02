# == Schema Information
#
# Table name: client_sites
# Database name: primary
#
#  id         :bigint           not null, primary key
#  address    :text
#  lat        :decimal(10, 7)
#  lng        :decimal(10, 7)
#  name       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  client_id  :bigint           not null
#  company_id :bigint           not null
#
# Indexes
#
#  index_client_sites_on_client_id           (client_id)
#  index_client_sites_on_client_id_and_name  (client_id,name) UNIQUE
#  index_client_sites_on_company_id          (company_id)
#
# Foreign Keys
#
#  fk_rails_...  (client_id => clients.id)
#  fk_rails_...  (company_id => companies.id)
#
# A place of a client (office, campus, centre). Corporate Shuttle stops can be marked as a site.
class ClientSite < ApplicationRecord
  include TenantScoped
  audited associated_with: :client

  belongs_to :client, inverse_of: :sites

  validates :name, presence: true, uniqueness: { scope: :client_id }
  validates :lat, numericality: { in: -90..90 }, allow_nil: true
  validates :lng, numericality: { in: -180..180 }, allow_nil: true
end
