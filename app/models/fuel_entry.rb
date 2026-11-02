# A refuel (diesel, petrol, AdBlue / DEF) or charge (electricity) of an own vehicle: quantity, cost, odometer, full or
# partial, company and station, the driver of the day and the receipt. km_since, efficiency and odometer_back are
# worked out by FuelEntries::Recompute over the vehicle's whole history.
# == Schema Information
#
# Table name: fuel_entries
# Database name: primary
#
#  id               :bigint           not null, primary key
#  cost             :decimal(12, 2)   not null
#  date             :date             not null
#  efficiency       :decimal(7, 1)
#  energy_km        :integer
#  full             :boolean          default(TRUE), not null
#  kind             :string           not null
#  km_since         :integer
#  note             :text
#  odometer         :integer
#  odometer_back    :integer
#  quantity         :decimal(10, 2)   not null
#  receipt          :string
#  station          :string
#  time             :integer
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  company_id       :bigint           not null
#  created_by_id    :bigint
#  document_read_id :bigint
#  driver_id        :bigint
#  fuel_company_id  :bigint
#  vehicle_id       :bigint           not null
#
# Indexes
#
#  index_fuel_entries_on_company_id_and_date  (company_id,date)
#  index_fuel_entries_on_created_by_id        (created_by_id)
#  index_fuel_entries_on_document_read_id     (document_read_id)
#  index_fuel_entries_on_driver_id            (driver_id)
#  index_fuel_entries_on_fuel_company_id      (fuel_company_id)
#  index_fuel_entries_on_vehicle_id_and_date  (vehicle_id,date)
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (created_by_id => users.id)
#  fk_rails_...  (document_read_id => document_reads.id)
#  fk_rails_...  (driver_id => drivers.id)
#  fk_rails_...  (fuel_company_id => fuel_companies.id)
#  fk_rails_...  (vehicle_id => vehicles.id)
#
class FuelEntry < ApplicationRecord
  include TenantScoped
  include MinuteTime
  audited

  KINDS = {
    "diesel" => { name: "Diesel", unit: "L" }, "petrol" => { name: "Petrol", unit: "L" },
    "def" => { name: "AdBlue (DEF)", unit: "L" }, "elec" => { name: "Electricity", unit: "kWh" }
  }.freeze
  # Kinds that share a tank (efficiency is measured within one).
  ENERGY = { "diesel" => "fuel", "petrol" => "fuel", "def" => "def", "elec" => "elec" }.freeze
  KIND_FILTERS = { "fuel" => %w[diesel petrol], "elec" => %w[elec], "def" => %w[def] }.freeze

  mount_uploader :receipt, DocumentUploader

  belongs_to :vehicle
  belongs_to :driver, optional: true
  belongs_to :fuel_company, optional: true
  belongs_to :document_read, optional: true
  belongs_to :created_by, class_name: "User", optional: true

  enum :kind, KINDS.keys.index_by(&:itself), validate: true

  minute_time :time

  normalizes :station, with: ->(v) { v.to_s.squish.presence }
  normalizes :note, with: ->(v) { v.to_s.strip.presence }

  validates :date, presence: { message: "must be picked" }
  validates :quantity, numericality: { greater_than: 0 }
  validates :cost, numericality: { greater_than_or_equal_to: 0 }
  validates :odometer, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validate { errors.add(:vehicle, "must be one of your own buses") if vehicle && !vehicle.own? }

  before_validation { self.full = false if def? }

  scope :chronological, -> { order(:date, Arel.sql("time NULLS FIRST"), :id) }
  scope :latest_first, -> { order(date: :desc).order(Arel.sql("time DESC NULLS LAST")).order(id: :desc) }
  scope :of_kind, ->(k) { KIND_FILTERS[k] ? where(kind: KIND_FILTERS[k]) : all }
  scope :in_month, ->(month) { where(date: month.beginning_of_month..month.end_of_month) }

  def energy = ENERGY[kind]
  def unit = KINDS[kind][:unit]
  def kind_name = KINDS[kind][:name]
  def unit_price = quantity.to_d.positive? ? (cost.to_d / quantity).round(3) : nil
end
