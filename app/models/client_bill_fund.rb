# A fund a school or company bills its bookings to (Convoy App › New Booking › Bill To: Admin Fund, CCA Fund, Parents
# Support Group ...). Kept per client; a removed fund stays on the bookings that used it.
# == Schema Information
#
# Table name: client_bill_funds
# Database name: primary
#
#  id           :bigint           not null, primary key
#  discarded_at :datetime
#  name         :string           not null
#  position     :integer          default(0), not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  client_id    :bigint           not null
#  company_id   :bigint           not null
#
# Indexes
#
#  index_client_bill_funds_on_client_and_name  (client_id, lower((name)::text)) UNIQUE WHERE (discarded_at IS NULL)
#  index_client_bill_funds_on_client_id        (client_id)
#  index_client_bill_funds_on_company_id       (company_id)
#
# Foreign Keys
#
#  fk_rails_...  (client_id => clients.id)
#  fk_rails_...  (company_id => companies.id)
#
class ClientBillFund < ApplicationRecord
  include TenantScoped
  include Discard::Model
  audited associated_with: :client

  belongs_to :client

  normalizes :name, with: ->(v) { v.to_s.squish }

  validates :name, presence: true, uniqueness: { scope: :client_id, case_sensitive: false, conditions: -> { kept } }
end
