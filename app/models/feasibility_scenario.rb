# A scenario of a feasibility study: bus sizes allowed, attendants (statutory / all buses), longest and target ride,
# margin, buffer buses per session and size ({ "AM" => { "MEDIUM_23" => 1 } }), engine parameter overrides; planned for AM
# and PM by the routing engine (result: a snapshot of the routes, served students, unassigned). stale = the study changed.
# == Schema Information
#
# Table name: feasibility_scenarios
# Database name: primary
#
#  id                   :bigint           not null, primary key
#  attendant            :string           default("STATUTORY"), not null
#  error                :text
#  extra_buses          :jsonb            not null
#  hard_cap             :integer          default(75), not null
#  margin_pct           :decimal(5, 2)    default(30.0), not null
#  name                 :string           not null
#  params               :jsonb            not null
#  position             :integer          not null
#  ran_at               :datetime
#  result               :jsonb
#  sizes                :string           default([]), not null, is an Array
#  stale                :boolean          default(FALSE), not null
#  status               :string           default("idle"), not null
#  target_cap           :integer          default(50), not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  feasibility_study_id :bigint           not null
#
# Indexes
#
#  index_feasibility_scenarios_on_feasibility_study_id  (feasibility_study_id)
#
# Foreign Keys
#
#  fk_rails_...  (feasibility_study_id => feasibility_studies.id) ON DELETE => cascade
#
class FeasibilityScenario < ApplicationRecord
  # Engine parameters a scenario may override (the prototype's Routing Parameters card). headroom = Seat Buffer, a
  # fraction (0.1 = 10% of the seats kept empty).
  PARAM_TIMES = %w[amTarget pmTarget].freeze
  PARAM_NUMBERS = { "baseDwell" => 0.., "perStudent" => 0.., "amTraffic" => 0.1.., "pmTraffic" => 0.1.., "headroom" => 0..0.9 }.freeze
  TIME = /\A([01]?\d|2[0-3]):[0-5]\d\z/
  PARAM_EFFORT = %w[low medium high extra max].freeze
  # Changing one of these after a run makes the result stale (the others only change the cost).
  RUN_FIELDS = %w[sizes attendant hard_cap target_cap params].freeze

  belongs_to :feasibility_study, inverse_of: :scenarios

  before_validation :clean_params

  validates :name, presence: true
  validates :attendant, inclusion: { in: %w[STATUTORY ALL_BUSES] }
  validates :status, inclusion: { in: %w[idle running done failed] }
  validates :margin_pct, numericality: { in: 0..90 }
  validates :hard_cap, :target_cap, numericality: { only_integer: true, greater_than: 0 }
  validate :sizes_known
  validate :params_valid

  # True when this save changes something the planning depends on.
  def run_changed? = RUN_FIELDS.intersect?(changes_to_save.keys)

  private

  def range_text(range) = range.end ? "from #{range.begin} to #{range.end}" : "of #{range.begin} or more"

  def sizes_known
    bad = sizes - SchoolBus::BUS_TYPES.keys
    errors.add(:sizes, "has unknown bus sizes: #{bad.join(', ')}") if bad.any?
  end

  # Blank values mean "company setting"; numbers sent as text become numbers (the engine needs them).
  def clean_params
    self.params = (params || {}).to_h.compact_blank.to_h do |k, v|
      v = v.to_d.to_f if PARAM_NUMBERS.key?(k) && v.is_a?(String) && v.match?(/\A\d+(\.\d+)?\z/)
      v = Clock.hm(Clock.minutes(v)) if PARAM_TIMES.include?(k) && v.is_a?(String) && v.match?(TIME)
      [ k, v ]
    end
  end

  def params_valid
    params.each do |k, v|
      if PARAM_TIMES.include?(k) then errors.add(:params, "#{k} must look like 06:50") unless v.to_s.match?(TIME)
      elsif PARAM_NUMBERS.key?(k) then errors.add(:params, "#{k} must be a number #{range_text(PARAM_NUMBERS[k])}") unless v.is_a?(Numeric) && PARAM_NUMBERS[k].cover?(v)
      elsif k == "effort" then errors.add(:params, "effort must be one of #{PARAM_EFFORT.join(', ')}") unless PARAM_EFFORT.include?(v)
      else errors.add(:params, "#{k} cannot be changed here")
      end
    end
  end
end
