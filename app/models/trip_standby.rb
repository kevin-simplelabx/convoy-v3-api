# == Schema Information
#
# Table name: trip_standbys
# Database name: primary
#
#  id              :bigint           not null, primary key
#  address         :text
#  lat             :decimal(10, 7)
#  lng             :decimal(10, 7)
#  location        :string           not null
#  minutes         :integer          default(10), not null
#  note            :text
#  street_view_url :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  company_id      :bigint           not null
#  trip_id         :bigint           not null
#
# Indexes
#
#  index_trip_standbys_on_company_id  (company_id)
#  index_trip_standbys_on_trip_id     (trip_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (trip_id => trips.id)
#
# Standby Area: where the bus waits before the first pick-up, and how many minutes before it reports there.
class TripStandby < ApplicationRecord
  include TenantScoped
  audited associated_with: :trip

  belongs_to :trip, inverse_of: :standby
  has_many :photos, -> { order(:position) }, class_name: "TripStandbyPhoto", dependent: :destroy, inverse_of: :standby

  accepts_nested_attributes_for :photos, allow_destroy: true

  validates :location, presence: true
  validates :minutes, numericality: { only_integer: true, in: 0..600 }
  validate { errors.add(:photos, "can be up to 3") if photos.reject(&:marked_for_destruction?).size > 3 }

  # Report by: the first pick-up time minus the standby minutes.
  def report_time = trip.start_time && (trip.start_time - minutes)
end
