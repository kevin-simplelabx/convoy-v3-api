# The monthly price an operator is paid for a School Bus route from a date (price history): Fixed Monthly, or Fixed +
# Per Rider (base_price for up to riders_included, then per_rider each). Without one, the school's default price for the
# route's bus size applies (Operator Pay).
# == Schema Information
#
# Table name: school_route_prices
# Database name: primary
#
#  id              :bigint           not null, primary key
#  base_price      :decimal(12, 2)
#  effective_from  :date             not null
#  mode            :string           default("fixed"), not null
#  monthly         :decimal(12, 2)
#  per_rider       :decimal(12, 2)
#  riders_included :integer
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  company_id      :bigint           not null
#  created_by_id   :bigint
#  school_route_id :bigint           not null
#
# Indexes
#
#  idx_on_school_route_id_effective_from_56e66aaed7  (school_route_id,effective_from) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (created_by_id => users.id)
#  fk_rails_...  (school_route_id => school_routes.id) ON DELETE => cascade
#
class SchoolRoutePrice < ApplicationRecord
  include TenantScoped
  audited associated_with: :school_route

  belongs_to :school_route
  belongs_to :created_by, class_name: "User", optional: true

  validates :mode, inclusion: { in: %w[fixed rider] }
  validates :effective_from, presence: true, uniqueness: { scope: :school_route_id }
  validate do
    if mode == "fixed" then errors.add(:monthly, "is needed") if monthly.nil?
    elsif [ base_price, riders_included, per_rider ].any?(&:nil?) then errors.add(:base, "Enter the base price, riders included and extra per rider")
    end
  end

  # Price for a month with this many riders.
  def amount(riders) = mode == "fixed" ? monthly : base_price + ([ riders - riders_included, 0 ].max * per_rider)
end
