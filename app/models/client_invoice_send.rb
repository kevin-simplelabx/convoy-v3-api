# An invoice recorded as emailed (or sent to a connected client's Convoy account). No email is sent yet.
# == Schema Information
#
# Table name: client_invoice_sends
# Database name: primary
#
#  id                :bigint           not null, primary key
#  cc_emails         :string           default([]), not null, is an Array
#  to_emails         :string           default([]), not null, is an Array
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  client_invoice_id :bigint           not null
#  sent_by_id        :bigint
#
# Indexes
#
#  index_client_invoice_sends_on_client_invoice_id  (client_invoice_id)
#  index_client_invoice_sends_on_sent_by_id         (sent_by_id)
#
# Foreign Keys
#
#  fk_rails_...  (client_invoice_id => client_invoices.id)
#  fk_rails_...  (sent_by_id => users.id)
#
class ClientInvoiceSend < ApplicationRecord
  belongs_to :client_invoice
  belongs_to :sent_by, class_name: "User", optional: true
end
