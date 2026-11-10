# == Schema Information
#
# Table name: school_plans
# Database name: primary
#
#  id                 :bigint           not null, primary key
#  adopted_at         :timestamptz
#  days               :integer          default([1, 2, 3, 4, 5]), not null, is an Array
#  effective_from     :date             not null
#  effective_to       :date
#  in_use             :boolean          default(TRUE), not null
#  name               :string           not null
#  params             :jsonb
#  priority           :string
#  riders_assigned_at :datetime
#  session            :string           not null
#  source             :string           default("manual"), not null
#  stale              :boolean          default(FALSE), not null
#  summary            :jsonb
#  unassigned         :jsonb            not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  adopted_by_id      :bigint
#  company_id         :bigint           not null
#  created_by_id      :bigint
#  routing_run_id     :bigint
#  school_id          :bigint           not null
#
# Indexes
#
#  index_school_plans_on_company_id      (company_id)
#  index_school_plans_on_routing_run_id  (routing_run_id)
#  index_school_plans_on_school_id       (school_id)
#
# Foreign Keys
#
#  fk_rails_...  (adopted_by_id => users.id)
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (created_by_id => users.id)
#  fk_rails_...  (routing_run_id => routing_runs.id) ON DELETE => nullify
#  fk_rails_...  (school_id => schools.id)
#
# A route plan of a school for one session (AM, PM, CCA), in use between two dates on its weekdays. Made by a routing
# run (source "engine"), drawn by hand ("manual") or seeded; a draft until adopted (in_use from effective_from:
# Scheduled before that date, Current after, Replaced once a later plan takes over). stale = Out of Date (its stops
# or riders changed since). summary / unassigned / params are the engine's figures as last worked out.
class SchoolPlan < ApplicationRecord
  include TenantScoped
  audited

  SESSIONS = { "am" => "AM", "pm" => "PM", "asa" => "CCA" }.freeze

  belongs_to :school
  belongs_to :routing_run, optional: true
  belongs_to :created_by, class_name: "User", optional: true
  belongs_to :adopted_by, class_name: "User", optional: true
  has_many :routes, -> { order(:number) }, class_name: "SchoolRoute", dependent: :destroy, inverse_of: :plan
  has_many :comments, -> { order(:created_at) }, class_name: "PlanComment", dependent: :delete_all
  has_many :plan_changes, -> { order(:created_at, :id) }, class_name: "SchoolPlanChange", dependent: :delete_all

  enum :session, SESSIONS.keys.index_by(&:itself), prefix: :session, validate: true

  validates :name, :effective_from, presence: true

  scope :running_between, lambda { |from, to|
    where(in_use: true).where(effective_from: ..to).where("effective_to IS NULL OR effective_to >= ?", from)
  }

  def session_name = SESSIONS[session]

  # draft, scheduled (adopted from a later date), current, replaced.
  def state(today = Date.current)
    return "draft" unless in_use
    return "scheduled" if effective_from > today
    return "replaced" if effective_to && effective_to < today

    "current"
  end
  # Calendar shifts: morning routes move on Late Arrival, the others on Early Dismissal.
  def calendar_session = session_am? ? "am" : "pm"
end
