# A line of a client invoice: a trip (its runs in the period), its late cancellations (each run can be waived) or a
# manual line (quantity × unit price, or an amount).
# == Schema Information
#
# Table name: client_invoice_lines
# Database name: primary
#
#  id                :bigint           not null, primary key
#  amount            :decimal(12, 2)   default(0.0), not null
#  amount_overridden :boolean          default(FALSE), not null
#  description       :string           not null
#  details           :text
#  period_text       :string
#  position          :integer          default(0), not null
#  quantity          :decimal(10, 2)   default(1.0), not null
#  ref               :string
#  source            :string           default("manual"), not null
#  unit_price        :decimal(12, 2)
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  client_invoice_id :bigint           not null
#  trip_id           :bigint
#
# Indexes
#
#  index_client_invoice_lines_on_client_invoice_id  (client_invoice_id)
#  index_client_invoice_lines_on_trip_id            (trip_id)
#
# Foreign Keys
#
#  fk_rails_...  (client_invoice_id => client_invoices.id)
#  fk_rails_...  (trip_id => trips.id)
#
class ClientInvoiceLine < ApplicationRecord
  audited associated_with: :client_invoice

  belongs_to :client_invoice, inverse_of: :lines
  belongs_to :trip, optional: true
  has_many :runs, -> { order(:occurrence_date, :start_time) }, class_name: "ClientInvoiceLineRun", dependent: :delete_all, inverse_of: :line

  enum :source, { trip: "trip", late_cancel: "late_cancel", manual: "manual" }, prefix: :from, validate: true

  validates :description, presence: true
  validates :amount, numericality: true

  # The runs billed on the line and their total (what a trip line comes to unless its amount was typed on the draft).
  def billed_runs = runs.to_a.reject(&:waived)
  def runs_amount = billed_runs.sum(0.to_d, &:amount)

  def refresh_amount!
    return if from_manual? || amount_overridden?

    update!(amount: runs_amount, quantity: billed_runs.length)
  end
end
