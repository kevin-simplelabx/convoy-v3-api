# == Schema Information
#
# Table name: operator_drivers
# Database name: primary
#
#  id                :bigint           not null, primary key
#  discarded_at      :datetime
#  display_name      :string
#  display_photo     :string
#  display_set_at    :datetime
#  invited_at        :datetime
#  name              :string           not null
#  notes             :text
#  phone             :string           not null
#  photo             :string
#  responded_at      :datetime
#  status            :string           default("pending"), not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  company_id        :bigint           not null
#  display_set_by_id :bigint
#  last_vehicle_id   :bigint
#  operator_id       :bigint           not null
#  vehicle_id        :bigint
#
# Indexes
#
#  index_operator_drivers_on_company_id             (company_id)
#  index_operator_drivers_on_company_id_and_status  (company_id,status)
#  index_operator_drivers_on_display_set_by_id      (display_set_by_id)
#  index_operator_drivers_on_last_vehicle_id        (last_vehicle_id)
#  index_operator_drivers_on_live_phone             (company_id,phone) UNIQUE WHERE (((status)::text = ANY ((ARRAY['pending'::character varying, 'active'::character varying])::text[])) AND (discarded_at IS NULL))
#  index_operator_drivers_on_operator_id            (operator_id)
#  index_operator_drivers_on_vehicle_id             (vehicle_id)
#  index_operator_drivers_one_per_vehicle           (vehicle_id) UNIQUE WHERE (vehicle_id IS NOT NULL)
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (display_set_by_id => users.id)
#  fk_rails_...  (last_vehicle_id => vehicles.id)
#  fk_rails_...  (operator_id => operators.id)
#  fk_rails_...  (vehicle_id => vehicles.id)
#
# A driver of a managed operator. Sits on at most one bus of their own operator.
# Invite states and mobile rules: InvitedDriver. Changing the operator takes the driver off a bus of the old one.
class OperatorDriver < ApplicationRecord
  include TenantScoped
  audited
  include InvitedDriver

  belongs_to :operator, inverse_of: :drivers
  has_many :app_sessions, class_name: "DriverAppSession", dependent: :delete_all
  belongs_to :vehicle, optional: true

  validates :vehicle_id, uniqueness: true, allow_nil: true
  validate :vehicle_of_operator, if: :vehicle
  validate :only_active_on_bus, if: :vehicle

  before_validation { self.vehicle = nil if !active? || (persisted? && operator_id_changed? && vehicle&.operator_id != operator_id) }
  # Runs on the bus it left and the bus it joined take their new driver.
  after_commit :refresh_runs, if: -> { saved_change_to_vehicle_id? }

  def self.ransackable_attributes(_auth = nil) = %w[name phone status operator_id]

  # Put this driver on a bus; the driver already there takes this driver's old bus (or none).
  def assign_vehicle!(new_vehicle)
    transaction do
      other = new_vehicle && OperatorDriver.where.not(id:).find_by(vehicle: new_vehicle)
      old = vehicle
      other&.update!(vehicle: nil)
      update!(vehicle: new_vehicle)
      other&.update!(vehicle: old)
    end
  end

  private

  def refresh_runs
    vehicle_id_previous_change.compact.each { |id| OccurrenceDriverJob.perform_later(company_id, id, Date.current.iso8601) }
  end

  def vehicle_of_operator
    errors.add(:vehicle, "belongs to another operator") if vehicle.operator_id != operator_id
  end

  def only_active_on_bus
    errors.add(:vehicle, "can only be given to an active driver") unless active?
  end
end
