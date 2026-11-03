# Switch Vehicle in the Convoy Driver app: the driver taking over a bus photographed it on all six sides (a photo can be
# marked up to point at damage) and signed the declaration. Linked to the schedule entry that gave them the bus, if any.
# == Schema Information
#
# Table name: vehicle_handovers
# Database name: primary
#
#  id                         :bigint           not null, primary key
#  at                         :datetime         not null
#  declared_at                :datetime         not null
#  note                       :text
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  client_id                  :uuid             not null
#  company_id                 :bigint           not null
#  driver_account_id          :bigint           not null
#  driver_id                  :bigint
#  operator_driver_id         :bigint
#  vehicle_driver_schedule_id :bigint
#  vehicle_id                 :bigint           not null
#
# Indexes
#
#  index_vehicle_handovers_on_driver_account_id_and_client_id  (driver_account_id,client_id) UNIQUE
#  index_vehicle_handovers_on_driver_id_and_at                 (driver_id,at)
#  index_vehicle_handovers_on_operator_driver_id_and_at        (operator_driver_id,at)
#  index_vehicle_handovers_on_vehicle_id                       (vehicle_id)
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (driver_account_id => driver_accounts.id)
#  fk_rails_...  (driver_id => drivers.id)
#  fk_rails_...  (operator_driver_id => operator_drivers.id)
#  fk_rails_...  (vehicle_driver_schedule_id => vehicle_driver_schedules.id) ON DELETE => nullify
#  fk_rails_...  (vehicle_id => vehicles.id)
#
class VehicleHandover < ApplicationRecord
  include TenantScoped
  audited

  SIDES = %w[front left right back odometer inside].freeze
  SIDE_LABELS = { "front" => "Front", "left" => "Left side", "right" => "Right side", "back" => "Back", "odometer" => "Odometer",
                  "inside" => "Inside" }.freeze

  belongs_to :vehicle
  belongs_to :driver_account
  belongs_to :driver, optional: true
  belongs_to :operator_driver, optional: true
  belongs_to :vehicle_driver_schedule, optional: true
  has_many :photos, -> { order(:id) }, class_name: "VehicleHandoverPhoto", dependent: :destroy, inverse_of: :handover

  validates :client_id, presence: true, uniqueness: { scope: :driver_account_id }
  validates :at, :declared_at, presence: true

  def member = driver || operator_driver
end
