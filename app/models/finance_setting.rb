# Finance > Finance Settings of a company (one row, made on first use). See the migration for the fields.
# == Schema Information
#
# Table name: finance_settings
# Database name: primary
#
#  id             :bigint           not null, primary key
#  account_name   :string
#  account_number :string
#  approval       :string           default("single"), not null
#  brand_address  :text
#  brand_email    :string
#  brand_name     :string
#  brand_note     :string           default("Thank you for riding with us.")
#  brand_phone    :string
#  brand_uen      :string
#  gst_mode       :string           default("excl"), not null
#  gst_on         :boolean          default(FALSE), not null
#  gst_rate       :decimal(5, 2)    default(9.0), not null
#  gst_reg_no     :string
#  locked_at      :datetime
#  payment_note   :string           default("Please pay by the due date and quote the invoice number.")
#  paynow         :string
#  prefix_cn      :string           default("CN"), not null
#  prefix_dn      :string           default("DN"), not null
#  prefix_inv     :string           default("INV"), not null
#  prefix_pb      :string           default("PB"), not null
#  prefix_pn      :string           default("PN"), not null
#  prefix_pv      :string           default("PV"), not null
#  prefix_rcp     :string           default("RCP"), not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  bank_id        :bigint
#  company_id     :bigint           not null
#  locked_by_id   :bigint
#
# Indexes
#
#  index_finance_settings_on_bank_id       (bank_id)
#  index_finance_settings_on_company_id    (company_id) UNIQUE
#  index_finance_settings_on_locked_by_id  (locked_by_id)
#
# Foreign Keys
#
#  fk_rails_...  (bank_id => banks.id)
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (locked_by_id => users.id)
#
class FinanceSetting < ApplicationRecord
  include TenantScoped
  audited

  DOC_TYPES = { "inv" => "Invoice", "cn" => "Credit Note", "dn" => "Debit Note", "rcp" => "Receipt", "pv" => "Payment Voucher",
                "pn" => "Payment Notice", "pb" => "Payment Batch" }.freeze

  belongs_to :bank, optional: true
  belongs_to :locked_by, class_name: "User", optional: true

  enum :gst_mode, { excl: "excl", incl: "incl" }, prefix: :gst, validate: true
  enum :approval, { single: "single", maker: "maker" }, prefix: :approval, validate: true

  DOC_TYPES.each_key { |t| normalizes :"prefix_#{t}", with: ->(v) { v.to_s.upcase.gsub(/[^A-Z0-9]/, "")[0, 6] } }

  def self.current = find_or_create_by!(company_id: ActsAsTenant.current_tenant.id)

  def locked? = locked_at.present?
  def prefix(type) = public_send(:"prefix_#{type}")
  def approvers = FinanceApprover.where(company_id:).includes(:user)

  # { sub, gst, total } of an amount: GST on top (excl) or inside it (incl); no GST when off. Rounded to cents.
  def self.split(amount, on:, rate:, mode:)
    amount = amount.to_d
    return { sub: amount.round(2), gst: 0.to_d, total: amount.round(2) } unless on

    if mode.to_s == "incl"
      gst = (amount * rate / (100 + rate)).round(2)
      { sub: amount - gst, gst:, total: amount.round(2) }
    else
      gst = (amount * rate / 100).round(2)
      { sub: amount.round(2), gst:, total: amount + gst }
    end
  end
end
