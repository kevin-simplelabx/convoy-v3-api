# Operator Payments: approved items paid together on a pay date (or one ad hoc payment), with a bank file and a payment
# notice per operator. Open = no bank file made and nothing paid yet (new approvals for its date join it).
# == Schema Information
#
# Table name: operator_pay_batches
# Database name: primary
#
#  id              :bigint           not null, primary key
#  bank_file_at    :datetime
#  kind            :string           default("batch"), not null
#  number          :string           not null
#  pay_date        :date             not null
#  transfer_type   :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  bank_file_by_id :bigint
#  company_id      :bigint           not null
#  created_by_id   :bigint
#
# Indexes
#
#  index_operator_pay_batches_on_bank_file_by_id          (bank_file_by_id)
#  index_operator_pay_batches_on_company_id_and_pay_date  (company_id,pay_date)
#  index_operator_pay_batches_on_created_by_id            (created_by_id)
#
# Foreign Keys
#
#  fk_rails_...  (bank_file_by_id => users.id)
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (created_by_id => users.id)
#
class OperatorPayBatch < ApplicationRecord
  include TenantScoped
  audited
  has_associated_audits

  belongs_to :created_by, class_name: "User", optional: true
  belongs_to :bank_file_by, class_name: "User", optional: true
  has_many :batch_operators, class_name: "OperatorPayBatchOperator", dependent: :destroy

  enum :kind, { batch: "batch", adhoc: "adhoc" }, prefix: :kind, validate: true

  def total = batch_operators.sum(0.to_d, &:total)
  def paid = batch_operators.sum(0.to_d, &:paid)
  def open? = bank_file_at.nil? && paid.zero?

  # Deductions only: every operator is nothing_to_pay, so there is no payment to make (see OperatorPayBatchOperator#status).
  def nothing_to_pay? = batch_operators.any? && batch_operators.all? { |bo| bo.status == "nothing_to_pay" }

  # paid | part_paid | nothing_to_pay | overdue | sent_to_bank | scheduled
  def status(today = Date.current)
    return "paid" if total.positive? && paid >= total
    return "part_paid" if paid.positive?
    return "nothing_to_pay" if nothing_to_pay?
    return "overdue" if pay_date < today
    return "sent_to_bank" if bank_file_at

    "scheduled"
  end
end
