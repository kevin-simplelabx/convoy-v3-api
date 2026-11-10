# == Schema Information
#
# Table name: replacements
# Database name: primary
#
#  id                  :bigint           not null, primary key
#  arranged_by         :string           default("operator"), not null
#  deduction           :decimal(12, 2)
#  driver_name         :string
#  driver_phone        :string
#  ends_on             :date             not null
#  eta                 :string
#  handover_stop       :string
#  handover_time       :integer
#  kind                :string           not null
#  original_share      :integer
#  pay_split           :string
#  premium             :decimal(12, 2)
#  reason              :text
#  run_date            :date
#  scope               :string           default("run"), not null
#  slot_no             :integer
#  starts_on           :date             not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  company_id          :bigint           not null
#  created_by_id       :bigint
#  driver_id           :bigint
#  operator_driver_id  :bigint
#  original_vehicle_id :bigint           not null
#  school_route_id     :bigint
#  trip_id             :bigint
#  trip_run_id         :bigint
#  vehicle_id          :bigint
#
# Indexes
#
#  index_replacements_on_company_id                            (company_id)
#  index_replacements_on_company_id_and_starts_on_and_ends_on  (company_id,starts_on,ends_on)
#  index_replacements_on_created_by_id                         (created_by_id)
#  index_replacements_on_driver_id                             (driver_id)
#  index_replacements_on_operator_driver_id                    (operator_driver_id)
#  index_replacements_on_original_vehicle_id                   (original_vehicle_id)
#  index_replacements_on_trip_id                               (trip_id)
#  index_replacements_on_trip_id_and_run_date                  (trip_id,run_date)
#  index_replacements_on_trip_run_id                           (trip_run_id)
#  index_replacements_on_vehicle_id                            (vehicle_id)
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (created_by_id => users.id)
#  fk_rails_...  (driver_id => drivers.id)
#  fk_rails_...  (operator_driver_id => operator_drivers.id)
#  fk_rails_...  (original_vehicle_id => vehicles.id)
#  fk_rails_...  (school_route_id => school_routes.id)
#  fk_rails_...  (trip_id => trips.id)
#  fk_rails_...  (trip_run_id => trip_runs.id)
#  fk_rails_...  (vehicle_id => vehicles.id)
#
# A replacement on the Scheduler (layer 4, applied on top of a run's bus): Driver Unavailable (drv, the bus is fine),
# Vehicle Down (veh, the original driver takes another bus), Crew Swap (crew, another bus and driver), Handover During
# the Trip (hand, riders move to another bus part way). For one run, or for drv / veh every run on the original bus in
# a date range (Driver Away, Vehicle Down on the vehicle panel).
class Replacement < ApplicationRecord
  include TenantScoped
  include MinuteTime
  audited

  KINDS = {
    "drv" => "Driver Unavailable", "veh" => "Vehicle Down", "crew" => "Crew Swap", "hand" => "Handover During the Trip"
  }.freeze

  belongs_to :trip, optional: true
  belongs_to :school_route, optional: true
  belongs_to :trip_run, optional: true
  belongs_to :original_vehicle, class_name: "Vehicle"
  belongs_to :vehicle, optional: true
  belongs_to :driver, optional: true
  belongs_to :operator_driver, optional: true
  belongs_to :created_by, class_name: "User", optional: true
  has_many :notifications, class_name: "ReplacementNotification", dependent: :destroy

  enum :kind, KINDS.keys.index_by(&:itself), prefix: :kind, validate: true
  enum :scope, { run: "run", range: "range" }, prefix: :for, validate: true
  enum :pay_split, { original: "original", new: "new", both: "both", split: "split" }, prefix: :pay_to, validate: { allow_nil: true }
  enum :arranged_by, { operator: "operator", us: "us" }, prefix: :arranged_by, validate: true

  normalizes :driver_phone, with: PhoneNormalizer

  minute_time :handover_time

  before_validation :dates_from_run, if: :for_run?

  validates :starts_on, :ends_on, presence: true
  validates :ends_on, comparison: { greater_than_or_equal_to: :starts_on }, if: -> { starts_on && ends_on }
  validates :run_date, :slot_no, presence: true, if: :for_run?
  validate { errors.add(:base, "Pick the run") if for_run? && trip_id.nil? && school_route_id.nil? }
  validates :vehicle, presence: { message: "must be picked" }, if: -> { kind_veh? || kind_crew? || kind_hand? }
  validate :new_driver_given, if: :kind_drv?
  validates :handover_stop, :handover_time, presence: true, if: :kind_hand?
  validates :pay_split, presence: true, if: :kind_hand?
  validates :original_share, numericality: { only_integer: true, in: 0..100 }, if: -> { kind_hand? && pay_to_split? }
  validates :deduction, :premium, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validate { errors.add(:vehicle, "must be another bus") if vehicle_id && vehicle_id == original_vehicle_id }
  validate { errors.add(:scope, "can only be a date range for Driver Unavailable or Vehicle Down") if for_range? && !(kind_drv? || kind_veh?) }

  scope :overlapping, ->(from, to) { where("starts_on <= ? AND ends_on >= ?", to, from) }

  def kind_name = KINDS[kind]
  def new_driver_label = driver&.name || operator_driver&.name || driver_name

  # Does it cover a run? A run replacement matches the run itself; a range one every run on the original bus.
  def covers?(trip_id, date, trip_run_id, slot_no, vehicle_id)
    return trip_id == self.trip_id && date == run_date && trip_run_id == self.trip_run_id && slot_no == self.slot_no if for_run?

    vehicle_id == original_vehicle_id && (starts_on..ends_on).cover?(date)
  end

  # Handover: share of the trip value for the original crew (part 1) and the new crew (part 2).
  def shares
    case pay_split
    when "original" then [ 1, 0 ]
    when "new" then [ 0, 1 ]
    when "both" then [ 1, 1 ]
    else [ original_share.to_i / 100.0, (100 - original_share.to_i) / 100.0 ]
    end
  end

  private

  def dates_from_run
    self.starts_on = self.ends_on = run_date if run_date
  end

  def new_driver_given
    errors.add(:base, "Pick the replacement driver") if driver_id.nil? && operator_driver_id.nil? && driver_name.blank?
  end
end
