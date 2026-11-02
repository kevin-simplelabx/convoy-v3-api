# == Schema Information
#
# Table name: client_end_customers
# Database name: primary
#
#  id         :bigint           not null, primary key
#  name       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  client_id  :bigint           not null
#  company_id :bigint           not null
#
# Indexes
#
#  index_client_end_customers_on_client_id           (client_id)
#  index_client_end_customers_on_client_id_and_name  (client_id,name) UNIQUE
#  index_client_end_customers_on_company_id          (company_id)
#
# Foreign Keys
#
#  fk_rails_...  (client_id => clients.id)
#  fk_rails_...  (company_id => companies.id)
#
# Someone a main contractor serves (Service For on a sub-contracted trip).
class ClientEndCustomer < ApplicationRecord
  include TenantScoped
  audited associated_with: :client

  belongs_to :client, inverse_of: :end_customers

  has_many :trips, dependent: :restrict_with_error
  has_many :bookings, dependent: :restrict_with_error

  normalizes :name, with: ->(v) { v.to_s.squish }

  validates :name, presence: true, uniqueness: { scope: :client_id, case_sensitive: false, message: "is already on the list" }
end
