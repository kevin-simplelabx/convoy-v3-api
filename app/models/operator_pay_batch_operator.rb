# One operator in a payment batch: its lines, payment notice (numbered when the bank file is made, with how it is paid
# then) and the payments recorded.
# == Schema Information
#
# Table name: operator_pay_batch_operators
# Database name: primary
#
#  id                    :bigint           not null, primary key
#  notice_number         :string
#  pay_method            :string
#  pay_to                :string
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  operator_id           :bigint           not null
#  operator_pay_batch_id :bigint           not null
#
# Indexes
#
#  index_operator_pay_batch_operators_on_operator_id  (operator_id)
#  index_operator_pay_batch_operators_unique          (operator_pay_batch_id,operator_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (operator_id => operators.id)
#  fk_rails_...  (operator_pay_batch_id => operator_pay_batches.id)
#
class OperatorPayBatchOperator < ApplicationRecord
  belongs_to :operator_pay_batch
  belongs_to :operator
  has_many :lines, -> { order(:item_on, :id) }, class_name: "OperatorPayBatchLine", dependent: :delete_all
  has_many :payments, -> { order(:paid_on, :id) }, class_name: "OperatorPayPayment", dependent: :delete_all

  def total = lines.sum(0.to_d, &:amount)
  def paid = payments.sum(0.to_d, &:amount)
  def left = [ total - paid, 0.to_d ].max

  # to_pay | part_paid | paid | nothing_to_pay (deductions only: there is no payment to make)
  def status
    return "nothing_to_pay" if total <= 0 && paid.zero?

    left.zero? ? "paid" : (paid.positive? ? "part_paid" : "to_pay")
  end
end
