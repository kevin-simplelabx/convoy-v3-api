# A payment made to an operator in a batch.
# == Schema Information
#
# Table name: operator_pay_payments
# Database name: primary
#
#  id                             :bigint           not null, primary key
#  amount                         :decimal(12, 2)   not null
#  method                         :string           not null
#  paid_on                        :date             not null
#  reference                      :string
#  created_at                     :datetime         not null
#  updated_at                     :datetime         not null
#  operator_pay_batch_operator_id :bigint           not null
#  recorded_by_id                 :bigint
#
# Indexes
#
#  index_operator_pay_payments_on_operator_pay_batch_operator_id  (operator_pay_batch_operator_id)
#  index_operator_pay_payments_on_recorded_by_id                  (recorded_by_id)
#
# Foreign Keys
#
#  fk_rails_...  (operator_pay_batch_operator_id => operator_pay_batch_operators.id)
#  fk_rails_...  (recorded_by_id => users.id)
#
class OperatorPayPayment < ApplicationRecord
  audited

  METHODS = %w[FAST GIRO Bank\ Transfer PayNow Cheque Cash].freeze

  belongs_to :operator_pay_batch_operator
  belongs_to :recorded_by, class_name: "User", optional: true

  validates :paid_on, presence: { message: "Pick the date paid" }
  validates :amount, numericality: { greater_than: 0, message: "Enter the amount paid" }
  validates :method, inclusion: { in: METHODS }
end
