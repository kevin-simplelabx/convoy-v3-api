# A day of a booking and its trips.
# == Schema Information
#
# Table name: booking_days
# Database name: primary
#
#  id         :bigint           not null, primary key
#  date       :date             not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  booking_id :bigint           not null
#  company_id :bigint           not null
#
# Indexes
#
#  index_booking_days_on_booking_id           (booking_id)
#  index_booking_days_on_booking_id_and_date  (booking_id,date) UNIQUE
#  index_booking_days_on_company_id           (company_id)
#  index_booking_days_on_company_id_and_date  (company_id,date)
#
# Foreign Keys
#
#  fk_rails_...  (booking_id => bookings.id)
#  fk_rails_...  (company_id => companies.id)
#
class BookingDay < ApplicationRecord
  include TenantScoped
  audited associated_with: :booking

  belongs_to :booking, inverse_of: :days
  has_many :trips, -> { order(:position) }, class_name: "BookingTrip", dependent: :destroy, inverse_of: :day

  validates :date, presence: true
end
