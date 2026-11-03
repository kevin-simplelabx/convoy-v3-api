# Route Charges (school pays per bus): an extra on a run's bus rate from starts_on — an amount (SGD) or a % of the rate
# (up to 100); 0 ends the charge. A route's history is its charges in date order. When a new plan is adopted, the
# charges of the old routes are carried to the best-matching new route with status "check" (or left with no route) for
# an Admin to confirm, move or drop.
# == Schema Information
#
# Table name: route_charges
# Database name: primary
#
#  id              :bigint           not null, primary key
#  kind            :string           default("amt"), not null
#  note            :string
#  reason          :string           not null
#  starts_on       :date             not null
#  status          :string           default("ok"), not null
#  value           :decimal(12, 2)   not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  carried_from_id :bigint
#  company_id      :bigint           not null
#  created_by_id   :bigint
#  school_id       :bigint           not null
#  school_route_id :bigint
#
# Indexes
#
#  index_route_charges_on_school_id_and_status  (school_id,status)
#  index_route_charges_on_school_route_id       (school_route_id)
#
# Foreign Keys
#
#  fk_rails_...  (carried_from_id => route_charges.id) ON DELETE => nullify
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (created_by_id => users.id)
#  fk_rails_...  (school_id => schools.id)
#  fk_rails_...  (school_route_id => school_routes.id) ON DELETE => nullify
#
class RouteCharge < ApplicationRecord
  include TenantScoped
  audited associated_with: :school

  REASONS = [ "Long route", "Peak timing", "ERP cover", "Extra stop", "Other" ].freeze

  belongs_to :school
  belongs_to :school_route, optional: true
  belongs_to :carried_from, class_name: "RouteCharge", optional: true
  belongs_to :created_by, class_name: "User", optional: true

  validates :kind, inclusion: { in: %w[amt pct] }
  validates :reason, inclusion: { in: REASONS }
  validates :status, inclusion: { in: %w[ok check] }
  validates :value, numericality: { greater_than_or_equal_to: 0 }
  validates :value, numericality: { less_than_or_equal_to: 100 }, if: -> { kind == "pct" }

  def amount(rate) = kind == "pct" ? (rate.to_d * value / 100).round(2) : value
end
