# == Schema Information
#
# Table name: trip_stops
# Database name: primary
#
#  id              :bigint           not null, primary key
#  address         :text
#  direction       :integer          default(1), not null
#  driver_note     :text
#  lat             :decimal(10, 7)
#  lng             :decimal(10, 7)
#  name            :string           not null
#  position        :integer          not null
#  return_name     :string
#  scheduled_time  :integer
#  street_view_url :string
#  use             :string           default("both"), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  client_site_id  :bigint
#  company_id      :bigint           not null
#  trip_id         :bigint           not null
#
# Indexes
#
#  index_trip_stops_on_client_site_id  (client_site_id)
#  index_trip_stops_on_company_id      (company_id)
#  index_trip_stops_on_trip_id         (trip_id)
#
# Foreign Keys
#
#  fk_rails_...  (client_site_id => client_sites.id)
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (trip_id => trips.id)
#
# A point on a trip's route, in order (direction 2 = a shuttle's own return stops).
class TripStop < ApplicationRecord
  include TenantScoped
  audited associated_with: :trip
  include MinuteTime

  USES = { "pu" => "Pick-up", "do" => "Drop-off", "both" => "Pick-up and Drop-off", "via" => "Waypoint Only" }.freeze
  MAX_PHOTOS = 3

  belongs_to :trip, inverse_of: :stops
  belongs_to :client_site, optional: true
  has_many :photos, -> { order(:position) }, class_name: "TripStopPhoto", dependent: :destroy, inverse_of: :stop
  has_many :students, -> { order(:position, :id) }, class_name: "TripStopStudent", dependent: :destroy, inverse_of: :trip_stop

  enum :use, USES.keys.index_by(&:itself), prefix: :use, validate: true
  minute_time :scheduled_time

  accepts_nested_attributes_for :photos, :students, allow_destroy: true

  validates :name, presence: true
  validates :direction, inclusion: { in: [ 1, 2 ] }
  validates :position, presence: true
  validates :lat, numericality: { in: -90..90 }, allow_nil: true
  validates :lng, numericality: { in: -180..180 }, allow_nil: true
  validate :photo_limit

  def waypoint? = use_via?

  private

  def photo_limit
    errors.add(:photos, "can be up to #{MAX_PHOTOS} per stop") if photos.reject(&:marked_for_destruction?).size > MAX_PHOTOS
  end
end
