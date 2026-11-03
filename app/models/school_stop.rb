# A Stop Library stop used by a school (linked), with the school's own catchment: postal codes and drawn areas
# ([{ name, latlngs: [[lat, lng], …], exclude, how: lasso|corners|lot }]; exclude areas cut riders out), and the points
# this school does not use (off_point_ids). A rider whose home is in the catchment may use the stop's points.
# == Schema Information
#
# Table name: school_stops
# Database name: primary
#
#  id            :bigint           not null, primary key
#  areas         :jsonb            not null
#  off_point_ids :bigint           default([]), not null, is an Array
#  postal_codes  :string           default([]), not null, is an Array
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  company_id    :bigint           not null
#  school_id     :bigint           not null
#  stop_id       :bigint           not null
#
# Indexes
#
#  index_school_stops_on_postal_codes           (postal_codes) USING gin
#  index_school_stops_on_school_id_and_stop_id  (school_id,stop_id) UNIQUE
#  index_school_stops_on_stop_id                (stop_id)
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (school_id => schools.id)
#  fk_rails_...  (stop_id => stops.id)
#
class SchoolStop < ApplicationRecord
  include TenantScoped
  audited associated_with: :school

  belongs_to :school
  belongs_to :stop

  validates :stop_id, uniqueness: { scope: :school_id }

  after_commit { school.update_column(:stops_changed_at, Time.current) } # rubocop:disable Rails/SkipsModelValidations

  # Is a rider's home (postal code, point) in the catchment?
  def covers?(postal, lat, lng)
    point = lat && [ lat, lng ]
    inside = postal_codes.include?(postal) || (point && include_areas.any? { Geo.inside?(point, it["latlngs"]) })
    inside && !(point && exclude_areas.any? { Geo.inside?(point, it["latlngs"]) })
  end

  def include_areas = Array(areas).reject { it["exclude"] }
  def exclude_areas = Array(areas).select { it["exclude"] }
  def catchment? = postal_codes.any? || include_areas.any?
end
