# One Run Routing of a school's session for a plan date: the engine input and parameters as sent, the engine result as
# it came back (both jsonb snapshots), riders left out (no stop / more than one stop), and the draft plan made from it.
# queued → running → done | failed (RoutingRunJob). kind "again" = Route Again on target_plan (its unlocked routes are
# replaced) instead of a new plan.
# == Schema Information
#
# Table name: routing_runs
# Database name: primary
#
#  id             :bigint           not null, primary key
#  conflict_rids  :string           default([]), not null, is an Array
#  error          :text
#  finished_at    :timestamptz
#  input          :jsonb            not null
#  kind           :string           default("new"), not null
#  ms             :integer
#  no_stop_rids   :string           default([]), not null, is an Array
#  params         :jsonb            not null
#  plan_date      :date             not null
#  result         :jsonb
#  session        :string           not null
#  started_at     :timestamptz
#  status         :string           default("queued"), not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  company_id     :bigint           not null
#  created_by_id  :bigint
#  school_id      :bigint           not null
#  target_plan_id :bigint
#
# Indexes
#
#  index_routing_runs_on_school_id_and_created_at  (school_id,created_at)
#  index_routing_runs_on_target_plan_id            (target_plan_id)
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (created_by_id => users.id)
#  fk_rails_...  (school_id => schools.id)
#  fk_rails_...  (target_plan_id => school_plans.id) ON DELETE => cascade
#
class RoutingRun < ApplicationRecord
  include TenantScoped

  belongs_to :school
  belongs_to :created_by, class_name: "User", optional: true
  has_one :plan, class_name: "SchoolPlan", dependent: :nullify
  belongs_to :target_plan, class_name: "SchoolPlan", optional: true

  enum :status, { queued: "queued", running: "running", done: "done", failed: "failed" }, validate: true
  enum :session, SchoolPlan::SESSIONS.keys.index_by(&:itself), prefix: :session, validate: true

  # The name the routing service keeps a run's progress under.
  def self.progress_key(id) = "routing_run-#{id}"
end
