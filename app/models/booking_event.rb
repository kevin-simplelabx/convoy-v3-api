# Something a client did on a booking that the coordinators hear about (the bell): a new booking from the Client Portal
# or the Convoy App, the client's own approval done or declined, changes accepted, a cancellation request.
# == Schema Information
#
# Table name: booking_events
# Database name: primary
#
#  id              :bigint           not null, primary key
#  actor_name      :string
#  kind            :string           not null
#  message         :string           not null
#  occurred_at     :datetime         not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  booking_id      :bigint           not null
#  booking_trip_id :bigint
#  company_id      :bigint           not null
#
# Indexes
#
#  index_booking_events_on_booking_id                  (booking_id)
#  index_booking_events_on_booking_trip_id             (booking_trip_id)
#  index_booking_events_on_company_id                  (company_id)
#  index_booking_events_on_company_id_and_occurred_at  (company_id,occurred_at)
#
# Foreign Keys
#
#  fk_rails_...  (booking_id => bookings.id)
#  fk_rails_...  (booking_trip_id => booking_trips.id)
#  fk_rails_...  (company_id => companies.id)
#
class BookingEvent < ApplicationRecord
  include TenantScoped

  KINDS = %w[new_booking client_approved client_declined acknowledged cancel_request].freeze
  WINDOW = 14.days

  belongs_to :booking, inverse_of: :events
  belongs_to :booking_trip, optional: true
  has_many :emails, class_name: "NotificationEmail", dependent: :nullify

  validates :kind, inclusion: { in: KINDS }
  validates :message, :occurred_at, presence: true

  scope :recent, ->(now = Time.current) { where(occurred_at: (now - WINDOW)..now).order(occurred_at: :desc) }
end
