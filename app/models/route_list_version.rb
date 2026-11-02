# == Schema Information
#
# Table name: route_list_versions
# Database name: primary
#
#  id          :bigint           not null, primary key
#  name        :string           not null
#  valid_until :date             not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  company_id  :bigint           not null
#  trip_id     :bigint           not null
#
# Indexes
#
#  index_route_list_versions_on_company_id               (company_id)
#  index_route_list_versions_on_trip_id                  (trip_id)
#  index_route_list_versions_on_trip_id_and_valid_until  (trip_id,valid_until)
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (trip_id => trips.id)
#
# An earlier route list of a School Run, in force until valid_until (Earlier Lists; the Passenger List of those dates).
class RouteListVersion < ApplicationRecord
  include TenantScoped

  belongs_to :trip
  has_many :stops, -> { order(:position) }, class_name: "RouteListVersionStop", dependent: :destroy, inverse_of: :version

  # Copy a trip's current stops and students into a version ending the day before `from`.
  def self.archive!(trip, from)
    version = trip.route_list_versions.create!(name: trip.route_list_name.presence || "Earlier list", valid_until: from - 1)
    trip.outbound_stops.each do |s|
      vs = version.stops.create!(position: s.position, name: s.name, scheduled_time: s.scheduled_time, address: s.address, driver_note: s.driver_note)
      s.students.each do |st|
        vs.students.create!(st.slice(:key, :position, :name, :class_name, :parent_name, :phone, :phone2, :note))
      end
    end
    version
  end
end
