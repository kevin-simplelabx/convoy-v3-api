# Where the bus waits before the first pick-up of a way (out or back), and how many minutes before it reports.
# == Schema Information
#
# Table name: booking_trip_standbys
# Database name: primary
#
#  id              :bigint           not null, primary key
#  lat             :decimal(10, 7)
#  leg             :string           default("out"), not null
#  lng             :decimal(10, 7)
#  location        :string           not null
#  minutes         :integer          default(10), not null
#  note            :text
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  booking_trip_id :bigint           not null
#  company_id      :bigint           not null
#
# Indexes
#
#  index_booking_trip_standbys_on_booking_trip_id_and_leg  (booking_trip_id,leg) UNIQUE
#  index_booking_trip_standbys_on_company_id               (company_id)
#
# Foreign Keys
#
#  fk_rails_...  (booking_trip_id => booking_trips.id)
#  fk_rails_...  (company_id => companies.id)
#
class BookingTripStandby < ApplicationRecord
  include TenantScoped

  belongs_to :trip, class_name: "BookingTrip", foreign_key: :booking_trip_id, inverse_of: :standbys

  validates :leg, inclusion: { in: %w[out back] }
  validates :location, presence: true
  validates :minutes, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end
