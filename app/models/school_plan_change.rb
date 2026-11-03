# A confirmed bus request written into a route plan version from its date: a child joins, moves, drops a session or leaves.
# == Schema Information
#
# Table name: school_plan_changes
# Database name: primary
#
#  id             :bigint           not null, primary key
#  from_date      :date             not null
#  op             :string           not null
#  rid            :string           not null
#  text           :string           not null
#  created_at     :timestamptz      not null
#  bus_request_id :bigint
#  school_plan_id :bigint           not null
#
# Indexes
#
#  index_school_plan_changes_on_bus_request_id  (bus_request_id)
#  index_school_plan_changes_on_school_plan_id  (school_plan_id)
#
# Foreign Keys
#
#  fk_rails_...  (bus_request_id => bus_requests.id) ON DELETE => nullify
#  fk_rails_...  (school_plan_id => school_plans.id) ON DELETE => cascade
#
class SchoolPlanChange < ApplicationRecord
  belongs_to :school_plan
  belongs_to :bus_request, optional: true

  validates :op, inclusion: { in: Plans::ApplyChange::OPS }
end
