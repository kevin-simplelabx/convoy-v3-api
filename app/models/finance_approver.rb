# Finance Settings > Operator Pay Run Approval: a user who can prepare and / or approve operator pay runs.
# == Schema Information
#
# Table name: finance_approvers
# Database name: primary
#
#  id          :bigint           not null, primary key
#  can_approve :boolean          default(FALSE), not null
#  can_prepare :boolean          default(TRUE), not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  company_id  :bigint           not null
#  user_id     :bigint           not null
#
# Indexes
#
#  index_finance_approvers_on_company_id_and_user_id  (company_id,user_id) UNIQUE
#  index_finance_approvers_on_user_id                 (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (user_id => users.id)
#
class FinanceApprover < ApplicationRecord
  include TenantScoped
  audited

  belongs_to :user
end
