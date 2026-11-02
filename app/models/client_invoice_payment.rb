# A payment a client made on an issued invoice.
# == Schema Information
#
# Table name: client_invoice_payments
# Database name: primary
#
#  id                :bigint           not null, primary key
#  amount            :decimal(12, 2)   not null
#  method            :string           not null
#  paid_on           :date             not null
#  reference         :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  client_invoice_id :bigint           not null
#  recorded_by_id    :bigint
#
# Indexes
#
#  index_client_invoice_payments_on_client_invoice_id  (client_invoice_id)
#  index_client_invoice_payments_on_recorded_by_id     (recorded_by_id)
#
# Foreign Keys
#
#  fk_rails_...  (client_invoice_id => client_invoices.id)
#  fk_rails_...  (recorded_by_id => users.id)
#
class ClientInvoicePayment < ApplicationRecord
  audited associated_with: :client_invoice

  METHODS = [ "Bank Transfer", "PayNow", "GIRO", "Cheque", "Cash" ].freeze

  belongs_to :client_invoice
  belongs_to :recorded_by, class_name: "User", optional: true

  validates :paid_on, presence: true
  validates :amount, numericality: { greater_than: 0 }
  validates :method, inclusion: { in: METHODS }
end
