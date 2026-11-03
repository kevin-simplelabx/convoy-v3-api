# == Schema Information
#
# Table name: trips
# Database name: primary
#
#  id                       :bigint           not null, primary key
#  airport_direction        :string
#  approved_riders_only     :boolean          default(FALSE), not null
#  booking_ref              :string
#  business_unit            :string
#  charge_no_school_days    :boolean          default(TRUE), not null
#  color                    :string
#  contractor_contact_name  :string
#  contractor_contact_phone :string
#  days                     :integer          default([]), not null, is an Array
#  discarded_at             :datetime
#  end_mode                 :string           default("none"), not null
#  end_time                 :integer          not null
#  ends_on                  :date
#  flight_number            :string
#  flight_time              :integer
#  guest_is_requestor       :boolean          default(TRUE), not null
#  guest_name               :string
#  guest_phone              :string
#  head_count               :boolean          default(FALSE), not null
#  hourly_rate              :boolean          default(FALSE), not null
#  hours                    :decimal(5, 2)
#  is_return                :boolean          default(FALSE), not null
#  kind                     :string           not null
#  label                    :string
#  lock_version             :integer          default(0), not null
#  luggage_cabin            :integer          default(0), not null
#  luggage_extra_large      :integer          default(0), not null
#  luggage_large            :integer          default(0), not null
#  luggage_medium           :integer          default(0), not null
#  luggage_on               :boolean          default(FALSE), not null
#  luggage_oversized        :integer          default(0), not null
#  meet_and_greet           :boolean          default(FALSE), not null
#  meet_and_greet_fee       :decimal(12, 2)   default(0.0), not null
#  no_fixed_bus             :boolean          default(FALSE), not null
#  notes                    :text
#  occurrence_count         :integer
#  operator_cancel_rule     :string           default("done"), not null
#  operator_cost            :decimal(12, 2)
#  paid_months_mode         :string           default("all"), not null
#  pax                      :integer          default(0), not null
#  price                    :decimal(12, 2)   default(0.0), not null
#  price_basis              :string           default("trip"), not null
#  price_by                 :string           default("all"), not null
#  price_per                :string           default("route"), not null
#  price_set                :string           default("same"), not null
#  project                  :string
#  requestor_email          :string
#  requestor_name           :string
#  requestor_phone          :string
#  require_contractor_app   :boolean          default(FALSE), not null
#  return_billing           :string
#  route_list_imported_at   :datetime
#  route_list_name          :string
#  route_tags               :string           default([]), not null, is an Array
#  school_time_estimated    :boolean          default(FALSE), not null
#  seat_reservation         :boolean          default(FALSE), not null
#  service_for              :string
#  session                  :string
#  shuttle_return           :boolean          default(FALSE), not null
#  shuttle_separate_return  :boolean          default(FALSE), not null
#  signboard_name           :string
#  skip_public_holidays     :boolean          default(TRUE), not null
#  start_time               :integer          not null
#  starts_on                :date             not null
#  students_purged_at       :datetime
#  subcontracted            :boolean          default(FALSE), not null
#  terminal                 :string
#  title                    :string           not null
#  trip_no                  :bigint           not null
#  trip_no_count            :integer          default(1), not null
#  trip_no_from             :date             not null
#  trip_value               :decimal(10, 2)   default(1.0), not null
#  trip_value_mode          :string           default("trips"), not null
#  trip_value_per           :string           default("run"), not null
#  trip_value_return        :decimal(10, 2)
#  trip_value_rounding      :string           default("up"), not null
#  unpaid_month_share       :integer          default(50), not null
#  unpaid_months            :integer          default([]), not null, is an Array
#  vehicles_count           :integer          default(1), not null
#  wait_minutes             :integer          default(0), not null
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  booking_trip_id          :bigint
#  calendar_id              :bigint
#  client_end_customer_id   :bigint
#  client_id                :bigint           not null
#  client_site_id           :bigint
#  company_id               :bigint           not null
#  created_by_id            :bigint
#  pair_id                  :bigint
#
# Indexes
#
#  index_trips_on_booking_trip_id                       (booking_trip_id)
#  index_trips_on_calendar_id                           (calendar_id)
#  index_trips_on_client_end_customer_id                (client_end_customer_id)
#  index_trips_on_client_id                             (client_id)
#  index_trips_on_client_site_id                        (client_site_id)
#  index_trips_on_company_id                            (company_id)
#  index_trips_on_company_id_and_kind                   (company_id,kind)
#  index_trips_on_company_id_and_starts_on_and_ends_on  (company_id,starts_on,ends_on)
#  index_trips_on_company_id_and_trip_no                (company_id,trip_no) UNIQUE
#  index_trips_on_created_by_id                         (created_by_id)
#  index_trips_on_discarded_at                          (discarded_at)
#  index_trips_on_pair_id                               (pair_id)
#  index_trips_on_route_tags                            (route_tags) USING gin
#
# Foreign Keys
#
#  fk_rails_...  (booking_trip_id => booking_trips.id)
#  fk_rails_...  (calendar_id => calendars.id)
#  fk_rails_...  (client_end_customer_id => client_end_customers.id)
#  fk_rails_...  (client_id => clients.id)
#  fk_rails_...  (client_site_id => client_sites.id)
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (created_by_id => users.id)
#  fk_rails_...  (pair_id => trips.id)
#
# A trip template, one-off or recurring. Its runs on each date and vehicle are occurrences (Phase 4).
# Times are minutes after midnight ("HH:MM" accepted); end_time passes 1440 when the trip ends after midnight.
class Trip < ApplicationRecord
  include TenantScoped
  audited
  has_associated_audits
  include Discard::Model
  include MinuteTime
  include TagList

  KIND_NAMES = {
    "ad_hoc" => "Ad Hoc / Charter", "corporate_shuttle" => "Corporate Shuttle", "airport_transfer" => "Airport Transfer",
    "disposal" => "Disposal", "school_run" => "School Run"
  }.freeze
  # Trip numbers kept for a series that never ends (one per day, about 10 years).
  NEVER_BLOCK_DAYS = 3653
  MAX_VEHICLES = 20
  MAX_ATTACHMENTS = 10
  # Everything the trip form and drawer show, loaded at once.
  FULL_INCLUDES = [ :client, :pair, :standby, :attachments, :route_vias, :run_groups,
                    { stops: %i[photos students], vehicle_slots: :vehicle, vehicle_requirements: :vehicle_type, standby: :photos,
                      runs: [ :times, { slots: :vehicle }, { trip: :stops } ], price_cells: :trip_run } ].freeze
  WEEKDAYS = (0..6).freeze

  belongs_to :client
  belongs_to :client_site, optional: true
  belongs_to :calendar, optional: true
  belongs_to :client_end_customer, optional: true
  belongs_to :booking_trip, optional: true, inverse_of: :scheduler_trips
  belongs_to :pair, class_name: "Trip", optional: true
  belongs_to :created_by, class_name: "User", optional: true

  has_many :stops, -> { order(:direction, :position) }, class_name: "TripStop", dependent: :destroy, inverse_of: :trip
  has_many :route_vias, -> { order(:direction, :from_position, :position) }, class_name: "TripRouteVia",
                                                                             dependent: :destroy, inverse_of: :trip
  has_many :vehicle_requirements, class_name: "TripVehicleRequirement", dependent: :destroy, inverse_of: :trip
  has_many :vehicle_slots, -> { order(:slot_no) }, class_name: "TripVehicleSlot", dependent: :destroy, inverse_of: :trip
  has_one :standby, class_name: "TripStandby", dependent: :destroy, inverse_of: :trip
  has_many :attachments, class_name: "TripAttachment", dependent: :destroy, inverse_of: :trip
  # validate: false: run errors are added to the trip as plain sentences (timetable_complete)
  has_many :runs, -> { order(:direction, :position) }, class_name: "TripRun", dependent: :destroy, inverse_of: :trip,
                  validate: false
  has_many :run_groups, class_name: "TripRunGroup", dependent: :destroy
  has_many :price_cells, class_name: "TripPriceCell", dependent: :delete_all
  has_many :route_list_versions, -> { order(:valid_until) }, dependent: :destroy
  has_many :assignments, -> { order(:effective_from, :id) }, class_name: "TripAssignment", dependent: :destroy
  has_many :time_changes, -> { order(:effective_from, :id) }, class_name: "TripTimeChange", dependent: :destroy
  has_many :occurrences, class_name: "TripOccurrence", dependent: :delete_all

  enum :kind, KIND_NAMES.keys.index_by(&:itself), validate: true
  enum :end_mode, { none: "none", never: "never", date: "date", count: "count" }, prefix: :ends, validate: true
  enum :price_per, { route: "route", vehicle: "vehicle" }, prefix: :price_per, validate: true
  enum :price_set, { same: "same", each: "each" }, prefix: :price, validate: true
  enum :price_basis, { trip: "trip", day: "day", month: "month" }, prefix: :charge_per, validate: true
  enum :trip_value_mode, { trips: "trips", hours: "hours" }, prefix: :trip_value_by, validate: true
  enum :trip_value_rounding, { up: "up", down: "down" }, prefix: :round, validate: true
  enum :operator_cancel_rule, { done: "done", full: "full" }, prefix: :operator_paid, validate: true
  enum :airport_direction, { arrival: "arrival", departure: "departure" }, validate: { allow_nil: true }
  enum :price_by, { all: "all", direction: "direction", run: "run" }, prefix: :price_by, validate: true
  enum :trip_value_per, { run: "run", day: "day" }, prefix: :trip_value_per, validate: true
  enum :session, { am: "am", pm: "pm" }, prefix: :session, validate: { allow_nil: true }
  enum :paid_months_mode, { all: "all", some: "some", part: "part" }, prefix: :paid_months, validate: true
  enum :return_billing, { two_way: "two_way", one_way: "one_way" }, prefix: :billed, validate: { allow_nil: true }

  minute_time :start_time, :end_time, :flight_time

  accepts_nested_attributes_for :stops, :route_vias, :vehicle_requirements, :vehicle_slots, :attachments, :runs, allow_destroy: true
  accepts_nested_attributes_for :standby, allow_destroy: true, update_only: true

  normalizes :days, with: ->(v) { Array(v).compact_blank.map(&:to_i).uniq.sort }
  tag_list :route_tags

  # Shuttle price table from the form: [{row: "all"|"d1"|"d1r0", col: "all"|"1", amount}] (written by Trips::Timetable).
  attr_accessor :price_cells_input

  def price_table=(cells)
    self.price_cells_input = Array(cells.respond_to?(:values) && !cells.is_a?(Array) ? cells.values : cells).map { |c| c.to_h.symbolize_keys }
  end

  before_validation :fill_defaults
  before_validation :shuttle_times_from_first_run, if: :corporate_shuttle?
  before_validation :school_run_times, if: :school_run?
  before_validation :work_out_end_time
  before_validation :work_out_last_date

  validates :title, :starts_on, presence: true
  validates :start_time, presence: true, numericality: { in: 0...1440 }, allow_nil: false
  validates :end_time, presence: true
  validates :hours, numericality: { greater_than: 0 }, if: :disposal?
  validates :vehicles_count, numericality: { only_integer: true, in: 1..MAX_VEHICLES }
  validates :pax, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :price, :meet_and_greet_fee, numericality: { greater_than_or_equal_to: 0 }
  validates :trip_value, numericality: { greater_than_or_equal_to: 0 }
  validates :wait_minutes, numericality: { greater_than: 0, message: "must be entered for an arrival" }, if: -> { airport_transfer? && arrival? }
  validates :airport_direction, presence: true, if: :airport_transfer?
  validate :end_differs_from_start
  validate :recurrence_complete
  validate :route_complete
  validate :vehicles_complete
  validate :belongs_to_client
  validate :timetable_complete, if: :corporate_shuttle?
  validates :session, presence: true, if: :school_run?
  validates :unpaid_month_share, numericality: { only_integer: true, in: 0..100 }
  validate { errors.add(:unpaid_months, "must be months 1 to 12") if unpaid_months.any? { |m| !m.to_i.between?(1, 12) } }
  validate { errors.add(:attachments, "can be up to #{MAX_ATTACHMENTS} files per trip") if attachments.reject(&:marked_for_destruction?).size > MAX_ATTACHMENTS }

  before_create :assign_trip_numbers
  before_update :assign_trip_numbers, if: :numbers_outgrown?

  scope :recurring, -> { where.not(days: []) }
  # Trips with runs on or after the date (never-ending, or last date not passed).
  scope :running_on, ->(date) { where("trips.end_mode = 'never' OR COALESCE(trips.ends_on, trips.starts_on) >= ?", date) }
  # Trips that may run between two dates.
  scope :active_between, lambda { |from, to|
    where(starts_on: ..to).where("trips.end_mode = 'never' OR COALESCE(trips.ends_on, trips.starts_on) >= ?", from)
  }
  scope :search, lambda { |q|
    next all if q.blank?

    term = q.to_s.strip
    number = term.delete_prefix("TID").to_i
    like = "%#{sanitize_sql_like(term)}%"
    left_joins(:client).where("trips.title ILIKE :q OR clients.name ILIKE :q OR trips.label ILIKE :q", q: like)
                       .or(left_joins(:client).where(trip_no: ..number).where("trips.trip_no + trips.trip_no_count > ?", number))
  }

  def self.ransackable_attributes(_auth = nil) = %w[kind client_id title starts_on ends_on trip_no]

  def kind_name = KIND_NAMES[kind]
  def recurring? = days.any?
  # Stops of a direction in travel order: Direction 2 has its own stops when they differ, else the outbound reversed.
  def stops_in(direction)
    kept = stops.reject(&:marked_for_destruction?).sort_by(&:position)
    return kept.select { |s| s.direction == 1 } if direction == 1

    shuttle_separate_return? ? kept.select { |s| s.direction == 2 } : kept.select { |s| s.direction == 1 }.reverse
  end

  def kept_runs = runs.reject(&:marked_for_destruction?)

  def pick_up = stops.find { |s| s.direction == 1 }
  def drop_off = stops.select { |s| s.direction == 1 }.last
  def outbound_stops = stops.select { |s| s.direction == 1 }
  def luggage_total = luggage_cabin + luggage_medium + luggage_large + luggage_extra_large + luggage_oversized

  # Last date the series runs (nil for one that never ends).
  def last_date = ends_never? ? nil : (ends_on || starts_on)

  # Trip ID on a date for a vehicle slot: TID + number (+ days since trip_no_from for recurring trips), -slot when 2+ vehicles.
  def trip_id_on(date = starts_on, slot = 1)
    offset = recurring? ? [ (date - trip_no_from).to_i, 0 ].max : 0
    base = "TID#{trip_no + offset}"
    vehicles_count > 1 ? "#{base}-#{slot}" : base
  end

  # Is the month (1..12) paid in full (1), not at all (0) or at the share for unticked months?
  def paid_share(month)
    return 1 if paid_months_all? || unpaid_months.exclude?(month)

    paid_months_some? ? 0 : unpaid_month_share / 100.0
  end

  private

  def fill_defaults
    self.end_mode = "none" if days.empty?
    self.end_mode = "never" if days.any? && ends_none?
    # A trip for a main contractor is sub-contracted unless the form says otherwise.
    self.subcontracted = true if new_record? && client&.main_contractor? && !subcontracted_changed?
    self.service_for = client_end_customer.name if client_end_customer && service_for.blank?
    self.title = default_title if title.blank?
  end

  # Trip Name is optional: the Service For customer on a sub-contracted trip, else the client.
  def default_title
    (subcontracted? && service_for.presence) || client&.name
  end

  # Disposal ends after its hours; an end at or before the start means the next day.
  def work_out_end_time
    return if start_time.nil?

    self.end_time = start_time + (hours.to_f * 60).round if disposal? && hours.to_f.positive?
    self.end_time += 1440 if end_time && end_time < start_time
  end

  # End: After N occurrences works out the last date from the calendar.
  def work_out_last_date
    return unless ends_count? && starts_on && occurrence_count.to_i >= 1 && company

    ctx = Calendars::Context.for(company, from: starts_on, to: starts_on + 10.years)
    self.ends_on = ctx.nth_run_date(starts_on, days:, count: occurrence_count, skip_public_holidays:, calendar_id:)
  end

  # A shuttle's start and end are its first run's (Direction 1, first timing).
  def shuttle_times_from_first_run
    first = kept_runs.each { |r| r.valid? if r.times_input }.min_by { |r| [ r.direction, r.position ] }
    return unless first&.start_time

    self.start_time = first.start_time
    self.end_time = first.end_time
  end

  def timetable_complete
    errors.add(:base, "Add at least one shuttle trip time") if kept_runs.empty?
    errors.add(:base, "Direction 2 runs need the return direction turned on") if !shuttle_return? && kept_runs.any? { |r| r.direction == 2 }
    if shuttle_separate_return? && stops_in(2).size < 2
      errors.add(:base, "Return stops: enter the first and last stop")
    end
    kept_runs.reject(&:valid?).each { |r| r.errors.full_messages.each { |m| errors.add(:base, m) } }
  end

  # School Run: the first stop with a time starts the trip; the school's time ends it (AM), else the last time given;
  # an AM run without the school's time is estimated from the last pick-up (the form may send a road-time estimate).
  # Passengers = the students on its stops.
  SCHOOL_ARRIVAL_MINUTES = 10

  def school_run_times
    out = outbound_stops.reject(&:marked_for_destruction?).sort_by(&:position)
    times = out.map(&:scheduled_time)
    known = times.compact
    if known.any?
      self.start_time = known.first
      if times.last
        self.end_time = times.last
        self.school_time_estimated = false
      else
        self.end_time = known.last + SCHOOL_ARRIVAL_MINUTES if end_time.nil? || end_time <= known.last
        self.school_time_estimated = session_am?
      end
    end
    count = out.sum { |s| s.students.reject(&:marked_for_destruction?).size }
    self.pax = [ count, pax.to_i ].max if count.positive?
  end

  def end_differs_from_start
    errors.add(:end_time, "must be different from the start time") if start_time && end_time && end_time == start_time
  end

  def recurrence_complete
    return unless recurring?

    errors.add(:days, "has a weekday that does not exist") if days.any? { |d| WEEKDAYS.exclude?(d) }
    errors.add(:ends_on, "must be on or after the first date") if ends_date? && (ends_on.nil? || ends_on < starts_on)
    errors.add(:occurrence_count, "must be at least 1") if ends_count? && occurrence_count.to_i < 1
  end

  def route_complete
    kept = stops.reject(&:marked_for_destruction?)
    errors.add(:stops, "have two points in the same place in the order") if kept.map { |s| [ s.direction, s.position ] }.uniq.size < kept.size
    out = kept.select { |s| s.direction == 1 }
    errors.add(:base, "Enter the pick-up point") if out.empty?
    errors.add(:base, "Enter the drop-off point") if !disposal? && out.size < 2
  end

  def vehicles_complete
    reqs = vehicle_requirements.reject(&:marked_for_destruction?)
    errors.add(:base, "Enter how many vehicles are needed") if reqs.empty?
    slots = vehicle_slots.reject(&:marked_for_destruction?)
    errors.add(:vehicle_slots, "can't be more than the vehicles required") if slots.any? { |s| s.slot_no > vehicles_count }
    errors.add(:vehicle_slots, "have the same slot twice") if slots.map(&:slot_no).uniq.size < slots.size
  end

  def belongs_to_client
    errors.add(:client_site, "is not a site of this client") if client_site && client_site.client_id != client_id
    errors.add(:client_end_customer, "is not one of this client's customers") if client_end_customer && client_end_customer.client_id != client_id
  end

  def number_block_days
    return 1 unless recurring?
    return NEVER_BLOCK_DAYS if ends_never?

    [ (last_date - starts_on).to_i + 1, 1 ].max
  end

  # A recurring trip whose dates moved out of its block of numbers gets a new block.
  def numbers_outgrown?
    return false unless trip_no
    return true if recurring? && trip_no_from > starts_on

    recurring? && (trip_no_from + trip_no_count - 1) < (last_date || (starts_on + NEVER_BLOCK_DAYS))
  end

  def assign_trip_numbers
    count = number_block_days
    self.trip_no = CompanySequence.next_block!(:trip_no, count, start: 100_001)
    self.trip_no_from = starts_on
    self.trip_no_count = count
  end
end
