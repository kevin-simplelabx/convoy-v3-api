# == Schema Information
#
# Table name: vehicle_driver_schedules
# Database name: primary
#
#  id            :bigint           not null, primary key
#  start_time    :integer          default(0), not null
#  starts_on     :date             not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  company_id    :bigint           not null
#  created_by_id :bigint
#  driver_id     :bigint
#  vehicle_id    :bigint           not null
#
# Indexes
#
#  index_vehicle_driver_schedules_on_company_id               (company_id)
#  index_vehicle_driver_schedules_on_created_by_id            (created_by_id)
#  index_vehicle_driver_schedules_on_driver_id                (driver_id)
#  index_vehicle_driver_schedules_on_driver_id_and_starts_on  (driver_id,starts_on)
#  index_vehicle_driver_schedules_on_vehicle_date_time        (vehicle_id,starts_on,start_time) UNIQUE
#  index_vehicle_driver_schedules_on_vehicle_id               (vehicle_id)
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (created_by_id => users.id)
#  fk_rails_...  (driver_id => drivers.id)
#  fk_rails_...  (vehicle_id => vehicles.id)
#
# Default driver of an own vehicle from a date. The entry in force on a date is the latest starts_on <= date.
class VehicleDriverSchedule < ApplicationRecord
  include TenantScoped
  include MinuteTime
  audited

  belongs_to :vehicle

  # From this time of day on starts_on (0 = the whole day): a driver switching buses at 06:30.
  minute_time :start_time

  # Runs on the vehicle from this date take the new default driver.
  after_commit { OccurrenceDriverJob.perform_later(company_id, vehicle_id, [ starts_on, starts_on_before_last_save ].compact.min.iso8601) }
  # Fuel entries count for the driver of the day.
  after_commit { FuelRecomputeJob.perform_later(company_id, vehicle_id) }
  # The driver's bell: a bus to take over later today or tomorrow.
  after_create_commit { DriverApp::RunNotifications.vehicle_switch(self) }
  belongs_to :driver, optional: true
  belongs_to :created_by, class_name: "User", optional: true

  validates :starts_on, presence: true, uniqueness: { scope: %i[vehicle_id start_time] }
  validates :start_time, numericality: { only_integer: true, in: 0...1440 }
  validate :own_vehicle
  validate :active_driver, if: :driver

  # Entries in force on a date: per vehicle, the latest one starting on or before the date (a change during the day counts
  # for the whole day).
  scope :current_on, lambda { |date|
    where(id: select("DISTINCT ON (vehicle_id) id").where(starts_on: ..date).order(:vehicle_id, starts_on: :desc, start_time: :desc))
  }
  # Entries in force at a minute of a date: per vehicle, the latest one started by then.
  scope :current_at, lambda { |date, minute|
    started = where("starts_on < :date OR (starts_on = :date AND start_time <= :minute)", date:, minute:)
    where(id: started.select("DISTINCT ON (vehicle_id) id").order(:vehicle_id, starts_on: :desc, start_time: :desc))
  }
  scope :upcoming, -> { where(starts_on: Date.current.next_day..) }

  def sort_key = [ starts_on, start_time ]

  # Started by a minute of a date (nil minute = any time that day).
  def started_by?(date, minute = nil) = starts_on < date || (starts_on == date && (minute.nil? || start_time <= minute))

  private

  def own_vehicle
    errors.add(:vehicle, "must be one of your own vehicles") if vehicle && !vehicle.own?
  end

  def active_driver
    errors.add(:driver, "must be an active driver") unless driver.active?
  end
end
