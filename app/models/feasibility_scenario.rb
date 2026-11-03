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
  belongs_to :feasibility_study, inverse_of: :scenarios

  validates :name, presence: true
  validates :attendant, inclusion: { in: %w[STATUTORY ALL_BUSES] }
  validates :status, inclusion: { in: %w[idle running done failed] }
  validates :margin_pct, numericality: { in: 0..90 }
end
