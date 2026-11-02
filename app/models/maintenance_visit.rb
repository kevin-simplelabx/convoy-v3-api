# == Schema Information
#
# Table name: maintenance_visits
# Database name: primary
#
#  id                 :bigint           not null, primary key
#  address            :text
#  completed_at       :datetime
#  date               :date             not null
#  driver_notified_at :datetime
#  end_time           :integer          not null
#  gst_on             :boolean          default(TRUE), not null
#  gst_rate           :decimal(5, 2)    default(9.0), not null
#  kind               :string           default("service"), not null
#  odometer           :integer
#  start_time         :integer          not null
#  status             :string           default("scheduled"), not null
#  work_to_do         :text
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  company_id         :bigint           not null
#  completed_by_id    :bigint
#  created_by_id      :bigint
#  driver_id          :bigint
#  vehicle_id         :bigint           not null
#  workshop_id        :bigint
#
# Indexes
#
#  index_maintenance_visits_on_company_id           (company_id)
#  index_maintenance_visits_on_company_id_and_date  (company_id,date)
#  index_maintenance_visits_on_completed_by_id      (completed_by_id)
#  index_maintenance_visits_on_created_by_id        (created_by_id)
#  index_maintenance_visits_on_driver_id            (driver_id)
#  index_maintenance_visits_on_vehicle_id           (vehicle_id)
#  index_maintenance_visits_on_vehicle_id_and_date  (vehicle_id,date)
#  index_maintenance_visits_on_workshop_id          (workshop_id)
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (completed_by_id => users.id)
#  fk_rails_...  (created_by_id => users.id)
#  fk_rails_...  (driver_id => drivers.id)
#  fk_rails_...  (vehicle_id => vehicles.id)
#  fk_rails_...  (workshop_id => workshops.id)
#
# A workshop visit of an own vehicle: planned (vehicle, driver, when, workshop, work to do), then recorded
# (odometer, invoice, line items, GST) and completed, or cancelled. Shown on the Scheduler as a block on the bus.
class MaintenanceVisit < ApplicationRecord
  include TenantScoped
  include MinuteTime
  audited
  has_associated_audits

  KINDS = { "service" => "Service", "repair" => "Repair", "tyres" => "Tyres", "inspection" => "Inspection", "other" => "Other" }.freeze

  belongs_to :vehicle
  belongs_to :driver, optional: true
  belongs_to :workshop, optional: true
  belongs_to :completed_by, class_name: "User", optional: true
  belongs_to :created_by, class_name: "User", optional: true
  has_many :lines, -> { order(:position, :id) }, class_name: "MaintenanceLine", dependent: :destroy, inverse_of: :visit
  has_many :invoices, class_name: "MaintenanceInvoice", dependent: :destroy, inverse_of: :visit

  enum :kind, KINDS.keys.index_by(&:itself), validate: true
  enum :status, { scheduled: "scheduled", completed: "completed", cancelled: "cancelled" }, validate: true

  minute_time :start_time, :end_time
  accepts_nested_attributes_for :lines, allow_destroy: true

  before_save :mark_driver_told

  validates :date, :start_time, :end_time, presence: true
  validates :end_time, comparison: { greater_than: :start_time, message: "must be after the start" }, if: -> { start_time && end_time }
  validates :workshop, presence: { message: "must be picked" }
  validates :gst_rate, numericality: { in: 0..100 }
  validate { errors.add(:vehicle, "must be one of your own buses") if vehicle && !vehicle.own? }
  validate :record_complete, if: :completed?

  scope :between, ->(from, to) { where(date: from..to) }
  scope :on_grid, -> { where.not(status: "cancelled") }

  def kind_name = KINDS[kind]

  def subtotal = lines.reject(&:marked_for_destruction?).sum(&:amount).round(2)
  def gst = gst_on? ? (subtotal * gst_rate / 100).round(2) : 0.to_d
  def total = subtotal + gst

  # The highest odometer recorded for the vehicle before this visit (the form warns when the new one is lower).
  def last_odometer
    MaintenanceVisit.where(vehicle_id:).where.not(id:).where(date: ..date).maximum(:odometer)
  end

  def starts_at = Time.zone.local(date.year, date.month, date.day) + start_time.minutes
  def ends_at = Time.zone.local(date.year, date.month, date.day) + end_time.minutes

  private

  def record_complete
    kept = lines.reject(&:marked_for_destruction?)
    errors.add(:odometer, "must be entered") unless odometer.to_i.positive?
    errors.add(:base, "Add the line items from the invoice") if kept.empty?
    errors.add(:base, "Every line item needs a description") if kept.any? { |l| l.description.blank? && !l.tyre? }
    positions = vehicle&.tyre_positions || []
    errors.add(:base, "Pick the position of each tyre") if kept.any? { |l| l.tyre? && positions.exclude?(l.tyre_position) }
  end

  # The driver is told (recorded) when the visit is new or its driver, date, time or workshop changes.
  def mark_driver_told
    return if driver_id.nil? || cancelled?

    self.driver_notified_at = Time.current if new_record? || will_save_change_to_driver_id? || will_save_change_to_date? ||
                                              will_save_change_to_start_time? || will_save_change_to_workshop_id?
  end
end
