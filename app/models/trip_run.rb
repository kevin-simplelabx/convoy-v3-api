# == Schema Information
#
# Table name: trip_runs
# Database name: primary
#
#  id             :bigint           not null, primary key
#  direction      :integer          default(1), not null
#  end_time       :integer          not null
#  position       :integer          not null
#  standby_needed :boolean          default(TRUE), not null
#  start_time     :integer          not null
#  trip_value     :decimal(10, 2)
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  company_id     :bigint           not null
#  trip_id        :bigint           not null
#
# Indexes
#
#  index_trip_runs_on_company_id  (company_id)
#  index_trip_runs_on_trip_id     (trip_id)
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (trip_id => trips.id)
#
# One timed run of a shuttle in a direction. `times` (write) takes the stop times in travel order of the direction
# ("07:30", "07:45", "" for a stop the run skips); start and end come from the first and last time given.
class TripRun < ApplicationRecord
  include TenantScoped
  audited associated_with: :trip
  include MinuteTime

  # A run is at least this long when its first and last stop share a time.
  MIN_MINUTES = 30

  belongs_to :trip, inverse_of: :runs
  has_many :times, class_name: "TripRunTime", dependent: :delete_all, inverse_of: :run
  has_many :slots, -> { order(:slot_no) }, class_name: "TripRunSlot", dependent: :destroy, inverse_of: :run
  has_many :price_cells, class_name: "TripPriceCell", dependent: :delete_all

  accepts_nested_attributes_for :slots, allow_destroy: true
  minute_time :start_time, :end_time

  attr_reader :times_input

  before_validation :times_to_start_and_end

  validates :direction, inclusion: { in: [ 1, 2 ] }
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :trip_value, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validate :times_in_order

  # "d1r0": direction and position, the key the price table and the front end use.
  def key = "d#{direction}r#{position}"
  def label = "Direction #{direction}, run #{position + 1}"

  def times=(list)
    @times_input = Array(list).map { |v| v.presence && Clock.minutes(v) }
  rescue ArgumentError
    @times_error = true
  end

  # Minutes at each stop in travel order, from the saved times (nil where the run skips the stop).
  def stop_minutes
    by_stop = times.to_h { |t| [ t.trip_stop_id, t.time ] }
    trip.stops_in(direction).map { |s| by_stop[s.id] }
  end

  private

  def times_to_start_and_end
    return if @times_input.nil?

    known = @times_input.compact
    return if known.empty?

    self.start_time = known.first
    self.end_time = known.last > known.first ? known.last : known.first + MIN_MINUTES
  end

  def times_in_order
    return errors.add(:base, "#{label}: times must look like 07:30") if @times_error
    return if @times_input.nil?

    expected = trip&.stops_in(direction)&.size
    errors.add(:base, "#{label}: give one time per stop (#{expected})") if expected && @times_input.size != expected
    errors.add(:base, "#{label}: enter the time at the first stop") if @times_input.first.nil?
    known = @times_input.compact
    errors.add(:base, "#{label}: each stop time must be later than the one before") if known.each_cons(2).any? { |a, b| b <= a }
  end
end
