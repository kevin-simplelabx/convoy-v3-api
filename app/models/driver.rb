# == Schema Information
#
# Table name: drivers
# Database name: primary
#
#  id                :bigint           not null, primary key
#  discarded_at      :datetime
#  display_name      :string
#  display_photo     :string
#  display_set_at    :datetime
#  invited_at        :datetime
#  name              :string           not null
#  phone             :string           not null
#  photo             :string
#  responded_at      :datetime
#  status            :string           default("pending"), not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  company_id        :bigint           not null
#  display_set_by_id :bigint
#  last_vehicle_id   :bigint
#
# Indexes
#
#  index_drivers_on_company_id             (company_id)
#  index_drivers_on_company_id_and_status  (company_id,status)
#  index_drivers_on_display_set_by_id      (display_set_by_id)
#  index_drivers_on_last_vehicle_id        (last_vehicle_id)
#  index_drivers_on_live_phone             (company_id,phone) UNIQUE WHERE (((status)::text = ANY ((ARRAY['pending'::character varying, 'active'::character varying])::text[])) AND (discarded_at IS NULL))
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (display_set_by_id => users.id)
#  fk_rails_...  (last_vehicle_id => vehicles.id)
#
# An own driver: added with name and mobile (an invite); they set up their own Convoy Driver account.
# Invite states and mobile rules: InvitedDriver.
class Driver < ApplicationRecord
  include TenantScoped
  audited
  include InvitedDriver

  has_many :vehicle_driver_schedules, dependent: :restrict_with_error
  has_many :pay_schemes, -> { order(:starts_on) }, class_name: "DriverPayScheme", dependent: :destroy
  has_many :pay_vehicle_types, -> { order(:starts_on) }, class_name: "DriverVehicleType", dependent: :destroy
  has_many :pay_months, class_name: "DriverPayMonth", dependent: :restrict_with_error

  def self.ransackable_attributes(_auth = nil) = %w[name phone status]

  # Vehicle this driver drives by default on a date (latest schedule entry on or before it).
  def vehicle_on(date)
    VehicleDriverSchedule.current_on(date).find_by(driver_id: id)&.vehicle
  end

  # Default driver changes still to come for this driver: [schedule entries].
  def upcoming_schedules = vehicle_driver_schedules.upcoming.includes(:vehicle).order(:starts_on)
end
