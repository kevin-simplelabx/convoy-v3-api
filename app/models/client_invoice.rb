# Finance > Client Invoices: an invoice to a client (or a site billed as its own entity), or a credit note against an
# issued invoice. Draft → issued (numbered) → void. Totals are kept on the row (recalculated on save).
# == Schema Information
#
# Table name: client_invoices
# Database name: primary
#
#  id              :bigint           not null, primary key
#  attention       :string
#  bill_to_address :text
#  bill_to_name    :string
#  bill_to_uen     :string
#  due_on          :date
#  gst             :decimal(12, 2)   default(0.0), not null
#  gst_mode        :string           default("excl"), not null
#  gst_on          :boolean          default(FALSE), not null
#  gst_rate        :decimal(5, 2)    default(0.0), not null
#  issued_at       :datetime
#  issued_on       :date
#  kind            :string           default("invoice"), not null
#  notes           :text
#  number          :string
#  period_from     :date
#  period_to       :date
#  po              :string
#  reason          :text
#  status          :string           default("draft"), not null
#  subtotal        :decimal(12, 2)   default(0.0), not null
#  terms_days      :integer          default(30), not null
#  total           :decimal(12, 2)   default(0.0), not null
#  voided_at       :datetime
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  client_id       :bigint           not null
#  client_site_id  :bigint
#  company_id      :bigint           not null
#  created_by_id   :bigint
#  invoice_id      :bigint
#  issued_by_id    :bigint
#  trip_id         :bigint
#  voided_by_id    :bigint
#
# Indexes
#
#  index_client_invoices_on_client_id                       (client_id)
#  index_client_invoices_on_client_site_id                  (client_site_id)
#  index_client_invoices_on_company_id_and_kind_and_status  (company_id,kind,status)
#  index_client_invoices_on_company_id_and_number           (company_id,number) UNIQUE WHERE (number IS NOT NULL)
#  index_client_invoices_on_created_by_id                   (created_by_id)
#  index_client_invoices_on_invoice_id                      (invoice_id)
#  index_client_invoices_on_issued_by_id                    (issued_by_id)
#  index_client_invoices_on_trip_id                         (trip_id)
#  index_client_invoices_on_voided_by_id                    (voided_by_id)
#
# Foreign Keys
#
#  fk_rails_...  (client_id => clients.id)
#  fk_rails_...  (client_site_id => client_sites.id)
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (created_by_id => users.id)
#  fk_rails_...  (invoice_id => client_invoices.id)
#  fk_rails_...  (issued_by_id => users.id)
#  fk_rails_...  (trip_id => trips.id)
#  fk_rails_...  (voided_by_id => users.id)
#
class ClientInvoice < ApplicationRecord
  include TenantScoped
  audited
  has_associated_audits

  belongs_to :client
  belongs_to :client_site, optional: true
  belongs_to :invoice, class_name: "ClientInvoice", optional: true
  belongs_to :trip, optional: true
  belongs_to :created_by, class_name: "User", optional: true
  belongs_to :issued_by, class_name: "User", optional: true
  belongs_to :voided_by, class_name: "User", optional: true
  has_many :lines, -> { order(:position, :id) }, class_name: "ClientInvoiceLine", dependent: :destroy, inverse_of: :client_invoice
  has_many :runs, through: :lines
  has_many :payments, -> { order(:paid_on, :id) }, class_name: "ClientInvoicePayment", dependent: :restrict_with_error
  has_many :credit_notes, -> { where(kind: "credit_note") }, class_name: "ClientInvoice", foreign_key: :invoice_id, inverse_of: :invoice,
                                                            dependent: :restrict_with_error
  has_many :sends, -> { order(:created_at) }, class_name: "ClientInvoiceSend", dependent: :delete_all

  enum :kind, { invoice: "invoice", credit_note: "credit_note" }, validate: true
  enum :status, { draft: "draft", issued: "issued", void: "void" }, validate: true
  enum :gst_mode, { excl: "excl", incl: "incl" }, prefix: :gst, validate: true

  normalizes :bill_to_name, :attention, :po, with: ->(v) { v.to_s.squish.presence }

  validates :terms_days, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  scope :not_void, -> { where.not(status: "void") }

  def period_label
    return nil unless period_from

    period_from == period_to || period_to.nil? ? period_from.strftime("%-d %b %Y") : "#{period_from.strftime('%-d %b')} to #{period_to.strftime('%-d %b %Y')}"
  end

  # Subtotal / GST / total from the lines (late cancellation lines count their runs not waived).
  def recalculate!
    lines.each(&:refresh_amount!)
    split = FinanceSetting.split(lines.sum(&:amount), on: gst_on, rate: gst_rate, mode: gst_mode)
    update!(subtotal: split[:sub], gst: split[:gst], total: split[:total])
  end

  def paid = payments.sum(0.to_d, &:amount)
  def credited = credit_notes.reject(&:void?).sum(0.to_d, &:total)
  def balance = [ total - paid - credited, 0.to_d ].max

  # Draft | Void | Paid | Overdue | Partly Paid | Issued (credit note: Issued | Void)
  def display_status(today = Date.current)
    return status unless issued? && invoice?
    return "paid" if balance <= 0.005
    return "overdue" if due_on && due_on < today
    return "partly_paid" if paid.positive? || credited.positive?

    "issued"
  end
end
