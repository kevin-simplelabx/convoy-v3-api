# A payment received on a School Bus bill: the date, amount, how it was paid and the reference. Recorded in Collections
# (with a receipt, which may pay several bills), when the first invoice is paid, or by the Convoy App (CCA rides).
# Voiding the receipt voids its payments, so the bills are owed again.
# == Schema Information
#
# Table name: school_bill_payments
# Database name: primary
#
#  id             :bigint           not null, primary key
#  amount         :decimal(12, 2)   not null
#  method         :string
#  paid_on        :date             not null
#  reference      :string
#  source         :string           default("console"), not null
#  voided_at      :timestamptz
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  receipt_id     :bigint
#  recorded_by_id :bigint
#  school_bill_id :bigint           not null
#
# Indexes
#
#  index_school_bill_payments_on_receipt_id      (receipt_id)
#  index_school_bill_payments_on_school_bill_id  (school_bill_id)
#
# Foreign Keys
#
#  fk_rails_...  (receipt_id => school_documents.id) ON DELETE => nullify
#  fk_rails_...  (recorded_by_id => users.id)
#  fk_rails_...  (school_bill_id => school_bills.id) ON DELETE => cascade
#
class SchoolBillPayment < ApplicationRecord
  SOURCES = %w[console app].freeze

  belongs_to :school_bill, inverse_of: :payments
  belongs_to :receipt, class_name: "SchoolDocument", optional: true
  belongs_to :recorded_by, class_name: "User", optional: true

  validates :paid_on, presence: true
  validates :amount, numericality: { greater_than: 0 }
  validates :source, inclusion: { in: SOURCES }

  scope :live, -> { where(voided_at: nil) }

  def voided? = voided_at.present?
end
