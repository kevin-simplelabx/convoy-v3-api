# A comment on a route plan (who, when, text).
# == Schema Information
#
# Table name: plan_comments
# Database name: primary
#
#  id             :bigint           not null, primary key
#  body           :text             not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  company_id     :bigint           not null
#  school_plan_id :bigint           not null
#  user_id        :bigint
#
# Indexes
#
#  index_plan_comments_on_school_plan_id  (school_plan_id)
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (school_plan_id => school_plans.id) ON DELETE => cascade
#  fk_rails_...  (user_id => users.id)
#
class PlanComment < ApplicationRecord
  include TenantScoped
  audited associated_with: :school_plan

  belongs_to :school_plan
  belongs_to :user, optional: true

  validates :body, presence: true
end
