# == Schema Information
#
# Table name: school_routes
# Database name: primary
#
#  id             :bigint           not null, primary key
#  end_time       :integer          not null
#  label          :string           not null
#  number         :integer          not null
#  riders_count   :integer          default(0), not null
#  start_time     :integer          not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  attendant_id   :bigint
#  company_id     :bigint           not null
#  school_plan_id :bigint           not null
#
# Indexes
#
#  index_school_routes_on_attendant_id               (attendant_id)
#  index_school_routes_on_company_id                 (company_id)
#  index_school_routes_on_school_plan_id             (school_plan_id)
#  index_school_routes_on_school_plan_id_and_number  (school_plan_id,number) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (attendant_id => attendants.id)
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (school_plan_id => school_plans.id)
#
# A route of a school plan, run on every school day of the plan: its regular bus comes from the vehicle changes
# (latest effective_from <= date), a replacement covers a few days.
class SchoolRoute < ApplicationRecord
  include TenantScoped
  include MinuteTime
  audited

  belongs_to :plan, class_name: "SchoolPlan", foreign_key: :school_plan_id, inverse_of: :routes
  belongs_to :attendant, optional: true
  has_many :stops, -> { order(:position) }, class_name: "SchoolRouteStop", dependent: :destroy, inverse_of: :route
  has_many :vehicle_changes, -> { order(:effective_from) }, class_name: "SchoolRouteVehicleChange", dependent: :destroy, inverse_of: :route
  has_many :replacements, -> { order(:starts_on) }, class_name: "SchoolRouteReplacement", dependent: :destroy, inverse_of: :route
  has_many :occurrences, class_name: "TripOccurrence", dependent: :delete_all

  minute_time :start_time, :end_time

  validates :label, presence: true
  validates :end_time, comparison: { greater_than: :start_time }, if: -> { start_time && end_time }

  delegate :school, to: :plan

  def title = "#{school.short} #{label}"

  # The regular bus on a date (nil = none).
  def regular_vehicle_id(date) = vehicle_changes.select { |c| c.effective_from <= date }.last&.vehicle_id

  def replacement_on(date) = replacements.reverse.find { |r| (r.starts_on..r.ends_on).cover?(date) }
end
