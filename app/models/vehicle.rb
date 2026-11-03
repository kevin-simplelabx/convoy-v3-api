# == Schema Information
#
# Table name: vehicles
# Database name: primary
#
#  id                  :bigint           not null, primary key
#  chassis_number      :string
#  coe_expires_on      :date
#  discarded_at        :datetime
#  driver_name         :string
#  driver_phone        :string
#  engine_number       :string
#  make                :string
#  model               :string
#  notes               :text
#  photo               :string
#  plate               :string           not null
#  registered_on       :date
#  road_tax_expires_on :date
#  seats               :integer
#  source              :string           default("console"), not null
#  tags                :string           default([]), not null, is an Array
#  year_made           :integer
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  company_id          :bigint           not null
#  operator_id         :bigint
#  vehicle_team_id     :bigint
#
# Indexes
#
#  index_vehicles_on_company_id            (company_id)
#  index_vehicles_on_company_id_and_plate  (company_id,plate) UNIQUE WHERE (discarded_at IS NULL)
#  index_vehicles_on_company_id_and_seats  (company_id,seats)
#  index_vehicles_on_discarded_at          (discarded_at)
#  index_vehicles_on_operator_id           (operator_id)
#  index_vehicles_on_tags                  (tags) USING gin
#  index_vehicles_on_vehicle_team_id       (vehicle_team_id)
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (operator_id => operators.id)
#  fk_rails_...  (vehicle_team_id => vehicle_teams.id)
#
# A bus. Ownership comes from its operator: none = own, managed operator = managed, external operator = external.
class Vehicle < ApplicationRecord
  include TenantScoped
  audited
  include Discard::Model
  include TagList

  # Scheduler size classes by seats, smallest first.
  SIZES = { "sedan" => 1..4, "mpv" => 5..7, "small" => 8..15, "medium" => 16..30, "large" => 31.. }.freeze
  SIZE_NAMES = { "sedan" => "Sedan", "mpv" => "MPV", "small" => "Small Bus", "medium" => "Medium Bus", "large" => "Large Bus" }.freeze
  VIP_PATTERN = "(^|[^a-z])vip([^a-z]|$)|alphard|vellfire".freeze
  OWNERSHIPS = %w[own managed external].freeze

  mount_uploader :photo, ImageUploader
  tag_list :tags

  belongs_to :operator, optional: true
  has_one :financial, class_name: "VehicleFinancial", dependent: :destroy
  has_many :finance_entries, class_name: "VehicleFinanceEntry", dependent: :destroy
  belongs_to :vehicle_team, optional: true
  has_many :driver_schedules, -> { order(:starts_on) }, class_name: "VehicleDriverSchedule", dependent: :destroy
  has_one :operator_driver, dependent: :nullify
  has_many :log_cards, -> { order(created_at: :desc) }, class_name: "VehicleLogCard", dependent: :destroy
  has_one :current_log_card, -> { current }, class_name: "VehicleLogCard"
  has_many :insurance_policies, class_name: "VehicleInsurancePolicy", dependent: :destroy
  has_one :current_insurance_policy, -> { current }, class_name: "VehicleInsurancePolicy"
  has_many :maintenance_visits, dependent: :restrict_with_error
  has_many :tracking_devices, dependent: :nullify
  has_one :live_position, class_name: "VehicleLivePosition", dependent: :delete

  normalizes :plate, with: ->(v) { v.to_s.gsub(/\s+/, "").upcase }
  normalizes :chassis_number, :engine_number, with: ->(v) { v.to_s.strip.upcase.presence }

  validates :plate, presence: true, uniqueness: { scope: :company_id, conditions: -> { kept } }
  validates :seats, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validates :year_made, numericality: { only_integer: true, in: 1980..2100 }, allow_nil: true
  validate :operator_same_company
  validate :dates_readable
  validate :plate_picked, on: :update

  OWNERSHIP_SQL = {
    "own" => "vehicles.operator_id IS NULL",
    "managed" => "operators.kind = 'managed'",
    "external" => "operators.kind = 'external'"
  }.freeze

  scope :own, -> { where(operator_id: nil) }
  scope :managed, -> { joins(:operator).merge(Operator.managed) }
  scope :external, -> { joins(:operator).merge(Operator.external) }
  scope :of_ownership, lambda { |kinds|
    sql = Array(kinds).filter_map { |k| OWNERSHIP_SQL[k] }
    sql.any? ? left_joins(:operator).where(sql.join(" OR ")) : all
  }
  scope :of_size, lambda { |keys|
    ranges = Array(keys).filter_map { |k| SIZES[k] }
    ranges.any? ? where(ranges.map { |r| arel_table[:seats].between(r) }.reduce(:or)) : all
  }
  scope :vip, lambda {
    where("'vip' = ANY(SELECT LOWER(unnest(vehicles.tags)))")
      .or(where("CONCAT_WS(' ', LOWER(vehicles.make), LOWER(vehicles.model)) ~ ?", VIP_PATTERN))
  }
  scope :tagged, ->(tags) { Array(tags).any? ? where("vehicles.tags @> ARRAY[?]::varchar[]", Array(tags)) : all }
  scope :search, lambda { |q|
    next all if q.blank?

    like = "%#{sanitize_sql_like(q.to_s.strip)}%"
    left_joins(:operator, :vehicle_team).where(<<~SQL.squish, q: like, today: Date.current)
      vehicles.plate ILIKE :q OR vehicles.make ILIKE :q OR vehicles.model ILIKE :q OR vehicles.driver_name ILIKE :q
      OR operators.name ILIKE :q OR vehicle_teams.name ILIKE :q
      OR EXISTS (SELECT 1 FROM operator_drivers od WHERE od.vehicle_id = vehicles.id AND od.name ILIKE :q)
      OR EXISTS (
        SELECT 1 FROM vehicle_driver_schedules s JOIN drivers d ON d.id = s.driver_id
        WHERE s.vehicle_id = vehicles.id AND d.name ILIKE :q
          AND s.starts_on = (SELECT MAX(s2.starts_on) FROM vehicle_driver_schedules s2 WHERE s2.vehicle_id = vehicles.id AND s2.starts_on <= :today)
      )
    SQL
  }
  # team_id: a team id, or "none" for vehicles without a team.
  scope :in_team, lambda { |team_id|
    next all if team_id.blank?

    team_id.to_s == "none" ? where(vehicle_team_id: nil) : where(vehicle_team_id: team_id)
  }
  # Scheduler sort: Own, Managed, External, then smallest first, then plate.
  scope :by_type, lambda {
    left_joins(:operator).order(Arel.sql("CASE WHEN vehicles.operator_id IS NULL THEN 0 WHEN operators.kind = 'managed' THEN 1 ELSE 2 END"))
      .order(Arel.sql("vehicles.seats ASC NULLS LAST"), :plate)
  }
  scope :smallest_first, -> { order(Arel.sql("vehicles.seats ASC NULLS LAST"), :plate) }
  scope :largest_first, -> { order(Arel.sql("vehicles.seats DESC NULLS LAST"), :plate) }

  def self.ransackable_attributes(_auth = nil) = %w[plate make model seats year_made vehicle_team_id operator_id]

  def ownership
    return "own" if operator_id.nil?

    operator.external? ? "external" : "managed"
  end

  def own? = operator_id.nil?

  # Tyre positions for maintenance lines, from the vehicle type its seats match (Convoy's tyre layout), plus the spare.
  def tyre_positions
    types = VehicleType.all.to_a
    type = types.find { |t| t.seats == seats.to_i } || types.find { |t| t.seats >= seats.to_i } || types.last
    layout = (type&.tyre_layout || (seats.to_i <= 15 ? "1-1" : "1-2")).split("-").map(&:to_i)
    names = layout.each_with_index.flat_map do |per_side, axle|
      place = axle.zero? ? "Front" : (axle == layout.size - 1 ? "Rear" : "Middle")
      per_side == 1 ? [ "#{place} Left", "#{place} Right" ] : [ "#{place} Left Outer", "#{place} Left Inner", "#{place} Right Inner", "#{place} Right Outer" ]
    end
    names = names.map { |n| n.sub(/\AMiddle/, "Rear 1").sub(/\ARear (Left|Right)/, 'Rear 2 \1') } if layout.size == 3 && layout[1] == 2
    names + [ "Spare" ]
  end

  # The current log card shows another plate: the vehicle can't be saved until one is picked.
  def plate_conflict? = current_log_card&.plate_conflict? || false

  def size
    SIZES.find { |_, range| range.cover?(seats) }&.first if seats
  end

  def vip?
    tags.any? { |t| t.casecmp?("vip") } || [ make, model ].compact.join(" ").downcase.match?(Regexp.new(VIP_PATTERN))
  end

  # Driver in force on a date: the default driver schedule for own buses, the operator driver for managed buses,
  # the typed name for external ones. Returns a Driver, an OperatorDriver or nil.
  def default_driver_on(date)
    return operator_driver if operator_id
    driver_schedules.select { |s| s.starts_on <= date }.max_by(&:starts_on)&.driver
  end

  private

  def plate_picked
    return unless plate_conflict? && changed?

    errors.add(:plate, "differs from the log card (#{current_log_card.plate_on_card}). Pick which plate is right first")
  end

  # Log card dates typed in the form: text that isn't a date is refused, not silently dropped.
  def dates_readable
    %i[registered_on coe_expires_on road_tax_expires_on].each do |attr|
      errors.add(attr, "is not a valid date") if self[attr].nil? && read_attribute_before_type_cast(attr).present?
    end
  end

  def operator_same_company
    errors.add(:operator, "is not one of your operators") if operator && operator.company_id != company_id
  end
end
