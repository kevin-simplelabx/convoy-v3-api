# Operator Payments > Add Item: an extra amount to pay an operator (positive) or to deduct (negative).
# == Schema Information
#
# Table name: operator_pay_items
# Database name: primary
#
#  id            :bigint           not null, primary key
#  amount        :decimal(12, 2)   not null
#  description   :string           not null
#  item_on       :date             not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  company_id    :bigint           not null
#  created_by_id :bigint
#  operator_id   :bigint           not null
#
# Indexes
#
#  index_operator_pay_items_on_company_id     (company_id)
#  index_operator_pay_items_on_created_by_id  (created_by_id)
#  index_operator_pay_items_on_operator_id    (operator_id)
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (created_by_id => users.id)
#  fk_rails_...  (operator_id => operators.id)
#
class OperatorPayItem < ApplicationRecord
  include TenantScoped
  audited

  belongs_to :operator
  belongs_to :created_by, class_name: "User", optional: true

  validates :description, presence: { message: "Describe the item" }
  validates :item_on, presence: { message: "Pick the date" }
  validates :amount, numericality: { other_than: 0, message: "Enter the amount" }
end
