# An approved item in a batch (a run, a replacement deduction or a manual item), kept by its ref so it is paid once.
# == Schema Information
#
# Table name: operator_pay_batch_lines
# Database name: primary
#
#  id                             :bigint           not null, primary key
#  amount                         :decimal(12, 2)   not null
#  approved_at                    :datetime
#  description                    :string           not null
#  details                        :string
#  item_on                        :date
#  ref                            :string           not null
#  source                         :string           not null
#  created_at                     :datetime         not null
#  updated_at                     :datetime         not null
#  approved_by_id                 :bigint
#  operator_pay_batch_operator_id :bigint           not null
#
# Indexes
#
#  idx_on_operator_pay_batch_operator_id_f3447135c0  (operator_pay_batch_operator_id)
#  index_operator_pay_batch_lines_on_approved_by_id  (approved_by_id)
#  index_operator_pay_batch_lines_on_ref             (ref) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (approved_by_id => users.id)
#  fk_rails_...  (operator_pay_batch_operator_id => operator_pay_batch_operators.id)
#
class OperatorPayBatchLine < ApplicationRecord
  belongs_to :operator_pay_batch_operator
  belongs_to :approved_by, class_name: "User", optional: true
end
