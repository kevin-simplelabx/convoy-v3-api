# A run billed on an invoice line. `active` is false once the invoice is void, so the run can be billed again.
# == Schema Information
#
# Table name: client_invoice_line_runs
# Database name: primary
#
#  id                     :bigint           not null, primary key
#  active                 :boolean          default(TRUE), not null
#  amount                 :decimal(12, 2)   not null
#  occurrence_date        :date             not null
#  start_time             :integer
#  trip_label             :string
#  waived                 :boolean          default(FALSE), not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  client_invoice_line_id :bigint           not null
#  occurrence_id          :bigint           not null
#
# Indexes
#
#  index_client_invoice_line_runs_billed_once                (occurrence_id,occurrence_date) UNIQUE WHERE active
#  index_client_invoice_line_runs_on_client_invoice_line_id  (client_invoice_line_id)
#
# Foreign Keys
#
#  fk_rails_...  (client_invoice_line_id => client_invoice_lines.id)
#
class ClientInvoiceLineRun < ApplicationRecord
  belongs_to :line, class_name: "ClientInvoiceLine", foreign_key: :client_invoice_line_id, inverse_of: :runs
end
