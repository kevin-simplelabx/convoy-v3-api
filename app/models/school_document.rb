# A School Finance document other than the bill itself: a credit note (taken off the bill, refunded to the payer, or
# taken off the payer's next bill), a debit note (added to the bill) or a receipt (one payment that pays one or more
# bills). Numbered from Finance Settings with the company's other documents; only a receipt can be made void.
# == Schema Information
#
# Table name: school_documents
# Database name: primary
#
#  id              :bigint           not null, primary key
#  bill_to         :string
#  credit_use      :string
#  description     :string
#  doc_type        :string           not null
#  gst_amount      :decimal(12, 2)   default(0.0), not null
#  gst_rate        :decimal(5, 2)    default(0.0), not null
#  issued_on       :date             not null
#  method          :string
#  number          :string           not null
#  payer           :string           default("family"), not null
#  reason          :text
#  reference       :string
#  refund_on       :date
#  subtotal        :decimal(12, 2)   default(0.0), not null
#  total           :decimal(12, 2)   not null
#  void_reason     :text
#  voided_at       :timestamptz
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  applied_bill_id :bigint
#  company_id      :bigint           not null
#  created_by_id   :bigint
#  family_id       :bigint
#  school_bill_id  :bigint
#  school_id       :bigint           not null
#  voided_by_id    :bigint
#
# Indexes
#
#  index_school_documents_on_applied_bill_id                       (applied_bill_id) WHERE (applied_bill_id IS NOT NULL)
#  index_school_documents_on_company_id_and_number                 (company_id,number) UNIQUE
#  index_school_documents_on_school_bill_id                        (school_bill_id)
#  index_school_documents_on_school_id_and_doc_type_and_issued_on  (school_id,doc_type,issued_on)
#
# Foreign Keys
#
#  fk_rails_...  (applied_bill_id => school_bills.id) ON DELETE => nullify
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (created_by_id => users.id)
#  fk_rails_...  (family_id => families.id) ON DELETE => nullify
#  fk_rails_...  (school_bill_id => school_bills.id) ON DELETE => cascade
#  fk_rails_...  (school_id => schools.id)
#  fk_rails_...  (voided_by_id => users.id)
#
class SchoolDocument < ApplicationRecord
  include TenantScoped
  audited associated_with: :school

  TYPES = { "cn" => "Credit Note", "dn" => "Debit Note", "rcp" => "Receipt" }.freeze
  USES = %w[reduce refund carry].freeze

  belongs_to :school
  belongs_to :school_bill, optional: true, inverse_of: :notes
  belongs_to :family, optional: true
  belongs_to :applied_bill, class_name: "SchoolBill", optional: true
  belongs_to :voided_by, class_name: "User", optional: true
  belongs_to :created_by, class_name: "User", optional: true
  has_many :payments, class_name: "SchoolBillPayment", foreign_key: :receipt_id, dependent: :nullify, inverse_of: :receipt

  validates :doc_type, inclusion: { in: TYPES.keys }
  validates :number, presence: true, uniqueness: { scope: :company_id }
  validates :credit_use, inclusion: { in: USES }, if: :credit_note?
  validates :school_bill, presence: true, unless: :receipt?

  scope :live, -> { where(voided_at: nil) }
  scope :credit_notes, -> { where(doc_type: "cn") }
  # Credit notes waiting for the payer's next bill.
  scope :carried, -> { credit_notes.live.where(credit_use: "carry", applied_bill_id: nil) }

  def credit_note? = doc_type == "cn"
  def debit_note? = doc_type == "dn"
  def receipt? = doc_type == "rcp"
  def voided? = voided_at.present?
  def type_name = TYPES[doc_type]

  # What it means for its bill now: Applied, Refunded, To Next Bill, Received, Issued or Void.
  def status_text
    return "Void" if voided?
    return "Received" if receipt?
    return "Issued" unless credit_note?

    { "reduce" => "Applied", "refund" => "Refunded" }[credit_use] || (applied_bill_id ? "Applied" : "To Next Bill")
  end
end
