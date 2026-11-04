# A trip a client asked for on a booking day: One Way, Two Way (a return later the same day), Disposal (hours) or
# Airport Transfer. Points of the way there (leg out) and, when changed, of the way back (leg back; else the way there
# reversed); a standby area for each way; the vehicles asked for by type. The estimate is kept as at the last save.
# == Schema Information
#
# Table name: booking_trips
# Database name: primary
#
#  id                             :bigint           not null, primary key
#  acknowledged_at                :datetime
#  acknowledged_by_name           :string
#  acknowledged_how               :string
#  airport_direction              :string
#  approval_how                   :string
#  approval_note                  :text
#  approved_at                    :datetime
#  cancelled_at                   :datetime
#  contact_name                   :string
#  contact_phone                  :string
#  distance_km                    :decimal(8, 1)
#  estimate_amount                :decimal(12, 2)   default(0.0), not null
#  estimate_lines                 :jsonb            not null
#  flight_number                  :string
#  hours                          :decimal(5, 2)
#  kind                           :string           not null
#  label                          :string
#  luggage_cabin                  :integer          default(0), not null
#  luggage_extra_large            :integer          default(0), not null
#  luggage_large                  :integer          default(0), not null
#  luggage_medium                 :integer          default(0), not null
#  luggage_on                     :boolean          default(FALSE), not null
#  luggage_oversized              :integer          default(0), not null
#  meet_and_greet                 :boolean          default(FALSE), not null
#  note                           :text
#  pax                            :integer          default(0), not null
#  position                       :integer          default(0), not null
#  rejected_at                    :datetime
#  rejected_by_name               :string
#  rejection_reason               :text
#  return_distance_km             :decimal(8, 1)
#  return_time                    :integer
#  signboard_name                 :string
#  start_time                     :integer          not null
#  status                         :string           default("pending"), not null
#  terminal                       :string
#  wait_minutes                   :integer
#  created_at                     :datetime         not null
#  updated_at                     :datetime         not null
#  acknowledged_by_client_user_id :bigint
#  acknowledged_by_id             :bigint
#  approved_by_id                 :bigint
#  booking_day_id                 :bigint           not null
#  booking_id                     :bigint           not null
#  company_id                     :bigint           not null
#  rejected_by_client_user_id     :bigint
#  rejected_by_id                 :bigint
#
# Indexes
#
#  index_booking_trips_on_acknowledged_by_client_user_id  (acknowledged_by_client_user_id)
#  index_booking_trips_on_acknowledged_by_id              (acknowledged_by_id)
#  index_booking_trips_on_booking_day_id                  (booking_day_id)
#  index_booking_trips_on_booking_id                      (booking_id)
#  index_booking_trips_on_company_id                      (company_id)
#  index_booking_trips_on_company_id_and_status           (company_id,status)
#  index_booking_trips_on_rejected_by_client_user_id      (rejected_by_client_user_id)
#
# Foreign Keys
#
#  fk_rails_...  (acknowledged_by_client_user_id => client_users.id)
#  fk_rails_...  (acknowledged_by_id => users.id)
#  fk_rails_...  (approved_by_id => users.id)
#  fk_rails_...  (booking_day_id => booking_days.id)
#  fk_rails_...  (booking_id => bookings.id)
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (rejected_by_client_user_id => client_users.id)
#  fk_rails_...  (rejected_by_id => users.id)
#
class BookingTrip < ApplicationRecord
  include TenantScoped
  include MinuteTime
  audited associated_with: :booking

  MAX_VEHICLES = 10
  MAX_STOPS = 5
  KIND_NAMES = { "one_way" => "Ad Hoc / Charter", "two_way" => "Ad Hoc / Charter, Two Way", "disposal" => "Disposal",
                 "airport" => "Airport Transfer" }.freeze
  LOCKED = %w[approved rejected cancelled].freeze
  APPROVAL_HOW = [ "Phone", "Email", "WhatsApp", "In person" ].freeze
  STATUS_LABELS = { "pending" => "Ready for Approval", "awaiting_ack" => "Pending Client Acknowledgement",
                    "awaiting_client" => "Awaiting Client Approval", "approved" => "Approved", "rejected" => "Rejected",
                    "cancelled" => "Cancelled" }.freeze

  include AASM

  self.ignored_columns += [ "rejected_by_client" ] # dropped 04/11/2026; remove this line after that release

  belongs_to :booking, inverse_of: :trips
  belongs_to :day, class_name: "BookingDay", foreign_key: :booking_day_id, inverse_of: :trips
  has_many :points, -> { order(:leg, :position) }, class_name: "BookingTripPoint", dependent: :delete_all, inverse_of: :trip
  has_many :standbys, class_name: "BookingTripStandby", dependent: :delete_all, inverse_of: :trip
  has_many :vehicles, class_name: "BookingTripVehicle", dependent: :delete_all, inverse_of: :trip
  has_many :changes_made, -> { order(:created_at) }, class_name: "BookingTripChange", dependent: :delete_all, inverse_of: :trip
  has_many :scheduler_trips, class_name: "Trip", dependent: :nullify, inverse_of: :booking_trip
  belongs_to :approved_by, class_name: "User", optional: true
  belongs_to :rejected_by, class_name: "User", optional: true
  include ActorStamp
  actor_stamp :acknowledged, :rejected

  enum :kind, KIND_NAMES.keys.index_by(&:itself), validate: true
  # pending (Ready for Approval) → approved | rejected. Edits by the company → awaiting_ack until the client acknowledges
  # (or we approve without waiting). Portal bookings with the client's own approval start awaiting_client.
  # The client may ask to cancel: cancelled (approved trips: their runs are cancelled).
  # Declined by the client: a rejection with no Convoy OS user (the client user in the Client Portal, or the client's
  # person we recorded before the portal).
  def rejected_by_client? = rejected_at.present? && rejected_by_id.nil?

  aasm column: :status, whiny_persistence: true do
    state :pending, initial: true
    state :awaiting_ack, :awaiting_client, :approved, :rejected, :cancelled

    event(:mark_changed) { transitions from: %i[pending awaiting_ack], to: :awaiting_ack }
    event(:acknowledge) { transitions from: :awaiting_ack, to: :pending }
    event(:approve) { transitions from: %i[pending awaiting_ack], to: :approved }
    event(:reject) { transitions from: %i[pending awaiting_ack], to: :rejected }
    event(:client_approve) { transitions from: :awaiting_client, to: :pending }
    event(:client_decline) { transitions from: :awaiting_client, to: :rejected }
    event(:cancel) { transitions from: %i[pending awaiting_ack awaiting_client approved], to: :cancelled }
  end

  # Set by Bookings::Assignment for approved trips: a Scheduler run of it has no vehicle yet.
  attr_accessor :unassigned
  enum :airport_direction, { arrival: "arrival", departure: "departure" }, validate: { allow_nil: true }

  minute_time :start_time, :return_time

  validates :status, inclusion: { in: STATUS_LABELS.keys }
  validates :pax, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  def locked? = LOCKED.include?(status)
  def status_label = approved? ? "Approved, #{unassigned ? 'Unassigned' : 'Assigned'}" : STATUS_LABELS[status]
  def kind_name = KIND_NAMES[kind]
  def date = day.date
  def out_points = points.select { |p| p.leg == "out" }.sort_by(&:position)

  # The way back: its own points once changed, else the way there reversed (pick-up and drop-off swapped).
  # It always starts where the way there ends.
  def back_points
    own = points.select { |p| p.leg == "back" }.sort_by(&:position)
    out = out_points
    list = own.size >= 2 ? own : out.reverse.map { |p| p.dup.tap { |b| b.use = BookingTripPoint.flip(p.use) } }
    return list if list.empty?

    list.first.assign_attributes(out.last.slice(:name, :address, :lat, :lng)) if out.any?
    list.first.use = "pu"
    list.last.use = "do"
    list
  end

  def own_way_back? = points.to_a.count { |p| p.leg == "back" } >= 2
  def standby(leg = "out") = standbys.find { |s| s.leg == leg }
  def vehicles_count = vehicles.sum(&:count)
  def seats_requested = vehicles.sum { |v| v.count * v.vehicle_type.seats }
  def arrival_with_meet_and_greet? = airport? && !departure? && meet_and_greet?

  # Stops between the first pick-up and the last drop-off.
  def stops_count(list = out_points) = [ list.size - 2, 0 ].max
end
