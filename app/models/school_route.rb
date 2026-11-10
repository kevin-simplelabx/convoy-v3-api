# == Schema Information
#
# Table name: school_routes
# Database name: primary
#
#  id                    :bigint           not null, primary key
#  attendant_price       :decimal(12, 2)
#  attendant_provided_by :string
#  attendant_required    :boolean
#  badges                :string           default([]), not null, is an Array
#  bus_type              :string
#  capacity              :integer
#  edited                :boolean          default(FALSE), not null
#  end_time              :integer          not null
#  engine_route          :jsonb
#  fill                  :decimal(5, 4)
#  floor                 :integer
#  hidden                :boolean          default(FALSE), not null
#  label                 :string           not null
#  locked                :boolean          default(FALSE), not null
#  manual                :boolean          default(FALSE), not null
#  number                :integer          not null
#  pay_to                :string
#  ride_minutes          :integer
#  riders_count          :integer          default(0), not null
#  route_key             :string
#  seats                 :integer
#  span_seconds          :integer
#  start_time            :integer          not null
#  student_seats         :integer
#  vias                  :jsonb            not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  attendant_id          :bigint
#  company_id            :bigint           not null
#  pay_to_operator_id    :bigint
#  school_plan_id        :bigint           not null
#
# Indexes
#
#  index_school_routes_on_attendant_id               (attendant_id)
#  index_school_routes_on_company_id                 (company_id)
#  index_school_routes_on_pay_to_operator_id         (pay_to_operator_id)
#  index_school_routes_on_school_plan_id             (school_plan_id)
#  index_school_routes_on_school_plan_id_and_number  (school_plan_id,number) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (attendant_id => attendants.id)
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (pay_to_operator_id => operators.id)
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
  belongs_to :pay_to_operator, class_name: "Operator", optional: true
  has_many :stops, -> { order(:position) }, class_name: "SchoolRouteStop", dependent: :destroy, inverse_of: :route
  has_many :vehicle_changes, -> { order(:effective_from) }, class_name: "SchoolRouteVehicleChange", dependent: :destroy, inverse_of: :route
  has_many :replacements, -> { order(:starts_on) }, class_name: "SchoolRouteReplacement", dependent: :destroy, inverse_of: :route
  has_many :occurrences, class_name: "TripOccurrence", dependent: :delete_all
  has_many :riders, class_name: "SchoolRouteRider", dependent: :delete_all
  has_many :prices, -> { order(:effective_from) }, class_name: "SchoolRoutePrice", dependent: :delete_all
  has_many :charges, -> { order(:starts_on, :id) }, class_name: "RouteCharge", dependent: :nullify

  minute_time :start_time, :end_time

  PAY_TO = %w[own operator].freeze

  validates :label, presence: true
  validates :attendant_provided_by, inclusion: { in: SchoolAttendantPolicy::PROVIDERS }, allow_nil: true
  validates :attendant_price, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :pay_to, inclusion: { in: PAY_TO }, allow_nil: true
  validates :pay_to_operator, presence: { message: "must be picked" }, if: -> { pay_to == "operator" }
  validates :end_time, comparison: { greater_than: :start_time }, if: -> { start_time && end_time }

  delegate :school, to: :plan

  def title = "#{school.short} #{label}"

  # The regular bus on a date (nil = none).
  # The bus type to show: its own, else the size nearest its seats (or the bus's).
  def bus_size(vehicle = nil) = bus_type || SchoolBus.size_for(seats || vehicle&.seats)

  def regular_vehicle_id(date) = vehicle_changes.select { |c| c.effective_from <= date }.last&.vehicle_id

  def replacement_on(date) = replacements.reverse.find { |r| (r.starts_on..r.ends_on).cover?(date) }

  # The badges shown: a route drawn by hand leads with "Manual" instead of "Edited" (Convoy OS res()).
  def shown_badges = manual ? [ "Manual", *(badges - %w[Edited Manual]) ] : badges
end
