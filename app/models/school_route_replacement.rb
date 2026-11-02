# == Schema Information
#
# Table name: school_route_replacements
# Database name: primary
#
#  id                   :bigint           not null, primary key
#  arranged_by          :string           default("operator"), not null
#  daily_rate           :decimal(12, 2)
#  deduct_from_operator :boolean          default(TRUE), not null
#  ends_on              :date             not null
#  reason               :text
#  starts_on            :date             not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  company_id           :bigint           not null
#  created_by_id        :bigint
#  school_route_id      :bigint           not null
#  vehicle_id           :bigint           not null
#
# Indexes
#
#  index_route_replacements_dates                      (school_route_id,starts_on,ends_on)
#  index_school_route_replacements_on_company_id       (company_id)
#  index_school_route_replacements_on_created_by_id    (created_by_id)
#  index_school_route_replacements_on_school_route_id  (school_route_id)
#  index_school_route_replacements_on_vehicle_id       (vehicle_id)
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (created_by_id => users.id)
#  fk_rails_...  (school_route_id => school_routes.id)
#  fk_rails_...  (vehicle_id => vehicles.id)
#
# A replacement bus on a route for a day or a date range. The route's operator arranges it (their pay is unchanged), or
# we do: the new bus is paid daily_rate a school day and, when deduct_from_operator, it comes off the operator's pay run.
class SchoolRouteReplacement < ApplicationRecord
  include TenantScoped
  audited associated_with: :route

  belongs_to :route, class_name: "SchoolRoute", foreign_key: :school_route_id, inverse_of: :replacements
  belongs_to :vehicle
  belongs_to :created_by, class_name: "User", optional: true

  enum :arranged_by, { operator: "operator", us: "us" }, prefix: :arranged_by, validate: true

  validates :starts_on, :ends_on, presence: true
  validates :ends_on, comparison: { greater_than_or_equal_to: :starts_on, message: "is before the start date" }, if: -> { starts_on && ends_on }
  validates :daily_rate, presence: { message: "must be entered (cost per day)" }, numericality: { greater_than: 0 }, if: :arranged_by_us?
end
