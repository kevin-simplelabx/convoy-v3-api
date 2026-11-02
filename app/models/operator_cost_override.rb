# Operator Payments: the cost Finance set for one run on an operator's bus (instead of its operator cost).
# == Schema Information
#
# Table name: operator_cost_overrides
# Database name: primary
#
#  id              :bigint           not null, primary key
#  amount          :decimal(12, 2)   not null
#  occurrence_date :date             not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  company_id      :bigint           not null
#  occurrence_id   :bigint           not null
#  set_by_id       :bigint
#
# Indexes
#
#  idx_on_occurrence_id_occurrence_date_f3ece8f775  (occurrence_id,occurrence_date) UNIQUE
#  index_operator_cost_overrides_on_company_id      (company_id)
#  index_operator_cost_overrides_on_set_by_id       (set_by_id)
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (set_by_id => users.id)
#
class OperatorCostOverride < ApplicationRecord
  include TenantScoped
  audited

  belongs_to :set_by, class_name: "User", optional: true

  validates :amount, numericality: { greater_than_or_equal_to: 0, message: "Enter a cost of 0 or more" }
end
