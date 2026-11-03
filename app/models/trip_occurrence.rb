# == Schema Information
#
# Table name: trip_occurrences
# Database name: primary
#
#  id                  :bigint           not null, primary key
#  cancelled_at        :timestamptz
#  cancelled_by_client :boolean          default(FALSE), not null
#  date                :date             not null
#  driver_name         :string
#  driver_phone        :string
#  end_time            :integer          not null
#  ended_at            :timestamptz
#  ends_at             :timestamptz      not null
#  issue_raised_at     :timestamptz
#  issue_reason        :text
#  kind                :string           not null
#  lock_version        :integer          default(0), not null
#  max_delay_minutes   :integer
#  operator_cost       :decimal(12, 2)
#  overridden_fields   :string           default([]), not null, is an Array
#  part                :integer          default(1), not null
#  pax                 :integer          default(0), not null
#  price               :decimal(12, 2)   default(0.0), not null
#  run_key             :string
#  shift_minutes       :integer          default(0), not null
#  skip_reason         :string
#  slot_no             :integer          default(1), not null
#  source_digest       :string
#  start_time          :integer          not null
#  started_at          :timestamptz
#  starts_at           :timestamptz      not null
#  status              :string           default("scheduled"), not null
#  trip_label          :string           not null
#  trip_value          :decimal(10, 2)   default(0.0), not null
#  created_at          :timestamptz      not null
#  updated_at          :timestamptz      not null
#  cancelled_by_id     :bigint
#  client_id           :bigint
#  company_id          :bigint           not null
#  driver_id           :bigint
#  issue_raised_by_id  :bigint
#  operator_driver_id  :bigint
#  operator_id         :bigint
#  original_vehicle_id :bigint
#  replacement_id      :bigint
#  school_route_id     :bigint
#  trip_assignment_id  :bigint
#  trip_id             :bigint
#  trip_run_id         :bigint
#  vehicle_id          :bigint
#
# Indexes
#
#  index_trip_occurrences_identity                 (COALESCE(trip_id, (0)::bigint), COALESCE(school_route_id, (0)::bigint), date, COALESCE(trip_run_id, (0)::bigint), slot_no, part) UNIQUE
#  index_trip_occurrences_on_company_date          (company_id,date)
#  index_trip_occurrences_on_driver_date           (driver_id,date) WHERE (driver_id IS NOT NULL)
#  index_trip_occurrences_on_id                    (id)
#  index_trip_occurrences_on_operator_driver_date  (operator_driver_id,date) WHERE (operator_driver_id IS NOT NULL)
#  index_trip_occurrences_on_route_date            (school_route_id,date) WHERE (school_route_id IS NOT NULL)
#  index_trip_occurrences_on_starts_at             (company_id,starts_at)
#  index_trip_occurrences_on_trip_date             (trip_id,date)
#  index_trip_occurrences_on_vehicle_date          (vehicle_id,date)
#  index_trip_occurrences_unassigned               (company_id,date) WHERE ((vehicle_id IS NULL) AND ((status)::text = 'scheduled'::text))
#
# Foreign Keys
#
#  trip_occurrences_cancelled_by_id_fkey      (cancelled_by_id => users.id)
#  trip_occurrences_client_id_fkey            (client_id => clients.id)
#  trip_occurrences_company_id_fkey           (company_id => companies.id)
#  trip_occurrences_driver_id_fkey            (driver_id => drivers.id)
#  trip_occurrences_issue_raised_by_id_fkey   (issue_raised_by_id => users.id)
#  trip_occurrences_operator_driver_id_fkey   (operator_driver_id => operator_drivers.id)
#  trip_occurrences_operator_id_fkey          (operator_id => operators.id)
#  trip_occurrences_original_vehicle_id_fkey  (original_vehicle_id => vehicles.id)
#  trip_occurrences_replacement_id_fkey       (replacement_id => replacements.id) ON DELETE => nullify
#  trip_occurrences_school_route_id_fkey      (school_route_id => school_routes.id)
#  trip_occurrences_trip_assignment_id_fkey   (trip_assignment_id => trip_assignments.id) ON DELETE => nullify
#  trip_occurrences_trip_id_fkey              (trip_id => trips.id)
#  trip_occurrences_trip_run_id_fkey          (trip_run_id => trip_runs.id) ON DELETE => nullify
#  trip_occurrences_vehicle_id_fkey           (vehicle_id => vehicles.id)
#
# One run of a trip on a date for a vehicle slot (and a shuttle run), with everything resolved: times, vehicle,
# driver, price. Written only by Occurrences services (Sync, actions); the table is partitioned by month on `date`.
class TripOccurrence < ApplicationRecord
  include TenantScoped
  include MinuteTime
  # Sync writes in bulk (no audit); changes made by people (cancel, move, time, issue) are audited with the trip.
  audited associated_with: :trip, except: %w[source_digest lock_version]

  self.primary_key = :id

  # Fields a person changed on this one run; Sync leaves them alone.
  OVERRIDABLE = %w[vehicle_id operator_cost shift_minutes status].freeze

  belongs_to :trip, optional: true
  belongs_to :school_route, optional: true
  belongs_to :trip_run, optional: true
  belongs_to :client, optional: true
  belongs_to :vehicle, optional: true
  belongs_to :driver, optional: true
  belongs_to :operator_driver, optional: true
  belongs_to :operator, optional: true
  belongs_to :original_vehicle, class_name: "Vehicle", optional: true
  belongs_to :trip_assignment, optional: true
  belongs_to :replacement, optional: true
  belongs_to :cancelled_by, class_name: "User", optional: true
  belongs_to :issue_raised_by, class_name: "User", optional: true
  # Trip History: notes and the driver's report point at the run by (occurrence_id, occurrence_date).
  has_many :history_notes, -> { order(:created_at) }, class_name: "OccurrenceNote", foreign_key: %i[occurrence_id occurrence_date],
                                                      primary_key: %i[id date], inverse_of: :occurrence, dependent: :delete_all
  has_one :driver_report, class_name: "OccurrenceDriverReport", foreign_key: %i[occurrence_id occurrence_date], primary_key: %i[id date],
                          inverse_of: :occurrence, dependent: :destroy
  has_one :correction, class_name: "OccurrenceCorrection", foreign_key: %i[occurrence_id occurrence_date], primary_key: %i[id date],
                       inverse_of: :occurrence, dependent: :destroy
  has_many :stop_events, -> { order(:position) }, class_name: "OccurrenceStopEvent", foreign_key: %i[occurrence_id occurrence_date],
                                                  primary_key: %i[id date], inverse_of: :occurrence, dependent: :delete_all
  has_one :trip_summary, class_name: "OccurrenceTripSummary", foreign_key: %i[occurrence_id occurrence_date], primary_key: %i[id date],
                         inverse_of: :occurrence, dependent: :delete
  has_many :positions, class_name: "OccurrencePosition", foreign_key: %i[occurrence_id occurrence_date], primary_key: %i[id date],
                       dependent: :delete_all
  has_many :ops_alerts, foreign_key: %i[occurrence_id occurrence_date], primary_key: %i[id date], inverse_of: :occurrence,
                        dependent: :delete_all

  # skipped: the calendar skips the date (public holiday, day off); kept for Trip History, never on the Scheduler.
  enum :status, { scheduled: "scheduled", cancelled: "cancelled", completed: "completed", removed: "removed", skipped: "skipped" },
       validate: true

  minute_time :start_time, :end_time

  scope :on, ->(date) { where(date:) }
  scope :between, ->(from, to) { where(date: from..to) }
  scope :in_month, ->(month) { between(month.beginning_of_month, month.end_of_month) }
  # Runs that are on the Scheduler, lists, pay and invoices (not removed, not skipped by the calendar).
  scope :visible, -> { where.not(status: %w[removed skipped]) }
  scope :unassigned, -> { scheduled.where(vehicle_id: nil) }
  scope :for_vehicle, ->(vehicle) { where(vehicle:) }
  # A driver's runs: own drivers by driver_id, operator drivers by operator_driver_id.
  scope :for_driver, ->(driver) { driver.is_a?(OperatorDriver) ? where(operator_driver: driver) : where(driver:) }
  scope :chronological, -> { order(:starts_at, :trip_label) }

  def self.ransackable_attributes(_auth = nil) = %w[date status kind client_id vehicle_id driver_id trip_id trip_label]

  def overridden?(field) = overridden_fields.include?(field.to_s)
  def issue? = issue_reason.present?

  # Identity used by Sync: one row per trip (or school route), date, run, slot and part.
  def identity = [ trip_id, school_route_id, date, trip_run_id, slot_no, part ]

  # Status shown on the grid: cancelled, done, live, unassigned, replaced or on time.
  def grid_status(now = Time.current)
    return vehicle_id ? "cancel" : "cancel_unassigned" if cancelled?
    return "done" if completed? || ended_at || ends_at <= now
    return "unassigned" if vehicle_id.nil?
    return "live" if starts_at <= now

    replacement_id && original_vehicle_id ? "replacement" : "ok"
  end

  # Status chip on the Trips page (RunSearch::STATUS_SQL is the same in SQL).
  def status_group(now = Time.current)
    return "cancelled" if cancelled?
    return "completed" if completed? || ended_at || ends_at <= now
    return "unassigned" if vehicle_id.nil?

    starts_at <= now ? "live" : "assigned"
  end
end
