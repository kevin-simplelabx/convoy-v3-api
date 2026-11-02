# Send Invoices To: a person on a client's (or a separately billed site's) invoices. To / CC get the invoice email;
# Attention prints the name as Attn on the invoice (an Attention-only person may have no email).
# == Schema Information
#
# Table name: client_billing_contacts
# Database name: primary
#
#  id            :bigint           not null, primary key
#  attention     :boolean          default(FALSE), not null
#  billable_type :string           not null
#  email         :string
#  name          :string
#  position      :integer          default(0), not null
#  send_as       :string           default("to"), not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  billable_id   :bigint           not null
#  company_id    :bigint           not null
#
# Indexes
#
#  index_client_billing_contacts_on_billable    (billable_type,billable_id)
#  index_client_billing_contacts_on_company_id  (company_id)
#  index_client_billing_contacts_unique_email   (billable_type,billable_id,email) UNIQUE WHERE (email IS NOT NULL)
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#
class ClientBillingContact < ApplicationRecord
  include TenantScoped
  audited

  MAX = 6

  belongs_to :billable, polymorphic: true

  enum :send_as, { to: "to", cc: "cc" }, prefix: :send, validate: true

  normalizes :name, with: ->(v) { v.to_s.squish.presence }
  normalizes :email, with: ->(v) { v.to_s.strip.downcase.presence }

  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP, message: "%{value} looks wrong" }, allow_nil: true
  validates :email, presence: { message: "is needed, or tick Attention" }, unless: :attention?
  validates :name, presence: { message: "is needed for the person under Attention" }, if: :attention?
end
