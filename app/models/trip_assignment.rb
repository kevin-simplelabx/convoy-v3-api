# == Schema Information
#
# Table name: trip_assignments
# Database name: primary
#
#  id             :bigint           not null, primary key
#  assignee       :string           not null
#  effective_from :date             not null
#  pay_amount     :decimal(12, 2)
#  pay_basis      :string           default("run"), not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  company_id     :bigint           not null
#  created_by_id  :bigint
#  operator_id    :bigint
#  trip_id        :bigint           not null
#  vehicle_id     :bigint
#
# Indexes
#
#  index_trip_assignments_on_company_id                  (company_id)
#  index_trip_assignments_on_created_by_id               (created_by_id)
#  index_trip_assignments_on_operator_id                 (operator_id)
#  index_trip_assignments_on_trip_id                     (trip_id)
#  index_trip_assignments_on_trip_id_and_effective_from  (trip_id,effective_from)
#  index_trip_assignments_on_vehicle_id                  (vehicle_id)
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (created_by_id => users.id)
#  fk_rails_...  (operator_id => operators.id)
#  fk_rails_...  (trip_id => trips.id)
#  fk_rails_...  (vehicle_id => vehicles.id)
#
# From effective_from on, who runs some vehicle slots of a trip: an own bus, an operator (bus named or not yet),
# or nobody (back to Unassigned). Written by the Assign page and by a drop From This Date On.
class TripAssignment < ApplicationRecord
  include TenantScoped
  audited associated_with: :trip

  belongs_to :trip
  belongs_to :operator, optional: true
  belongs_to :vehicle, optional: true
  belongs_to :created_by, class_name: "User", optional: true
  has_many :slots, class_name: "TripAssignmentSlot", dependent: :delete_all, inverse_of: :assignment

  enum :assignee, { own: "own", operator: "operator", none: "none" }, prefix: :to, validate: true
  enum :pay_basis, { run: "run", day: "day", month: "month" }, prefix: :pay_per, validate: true

  validates :effective_from, presence: true
  validates :pay_amount, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :operator, presence: true, if: :to_operator?
  validates :vehicle, presence: true, if: :to_own?
  validate :vehicle_fits

  # Slots it covers as "run_key|slot" ("d1r0|1"; "trip|2" for a trip that is not a shuttle).
  def slot_keys = slots.map(&:key)

  def covers?(trip_run_id, slot_no) = slots.any? { |s| s.trip_run_id == trip_run_id && s.slot_no == slot_no }

  private

  def vehicle_fits
    return if vehicle.nil?

    errors.add(:vehicle, "must be one of your own buses") if to_own? && !vehicle.own?
    errors.add(:vehicle, "belongs to another operator") if to_operator? && vehicle.operator_id != operator_id
  end
end
