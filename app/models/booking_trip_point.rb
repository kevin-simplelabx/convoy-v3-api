# A point of a booking trip, way there (out) or way back (back): pick-up, drop-off or both, a note for the driver.
# == Schema Information
#
# Table name: booking_trip_points
# Database name: primary
#
#  id              :bigint           not null, primary key
#  address         :string
#  lat             :decimal(10, 7)
#  leg             :string           default("out"), not null
#  lng             :decimal(10, 7)
#  name            :string           not null
#  note            :text
#  position        :integer          not null
#  use             :string           default("both"), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  booking_trip_id :bigint           not null
#  company_id      :bigint           not null
#
# Indexes
#
#  idx_on_booking_trip_id_leg_position_9ccf998ef7  (booking_trip_id,leg,position) UNIQUE
#  index_booking_trip_points_on_company_id         (company_id)
#
# Foreign Keys
#
#  fk_rails_...  (booking_trip_id => booking_trips.id)
#  fk_rails_...  (company_id => companies.id)
#
class BookingTripPoint < ApplicationRecord
  include TenantScoped

  USES = %w[pu do both].freeze

  belongs_to :trip, class_name: "BookingTrip", foreign_key: :booking_trip_id, inverse_of: :points

  validates :leg, inclusion: { in: %w[out back] }
  validates :use, inclusion: { in: USES }
  validates :name, presence: true

  def self.flip(use) = { "pu" => "do", "do" => "pu" }.fetch(use, "both")
  def pin = lat && lng ? [ lat.to_f, lng.to_f ] : nil
end
