# A sign-in to the Convoy Driver app by an own driver or an operator driver (Ops Control: is the driver logged in before
# the first pick-up). Signed out = signed_out_at. Written by the driver app (seed / simulator for now).
# == Schema Information
#
# Table name: driver_app_sessions
# Database name: primary
#
#  id                 :bigint           not null, primary key
#  last_seen_at       :timestamptz
#  signed_in_at       :timestamptz      not null
#  signed_out_at      :timestamptz
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  company_id         :bigint           not null
#  driver_id          :bigint
#  operator_driver_id :bigint
#  tracking_device_id :bigint
#
# Indexes
#
#  idx_on_operator_driver_id_signed_in_at_078880f84a        (operator_driver_id,signed_in_at) WHERE (operator_driver_id IS NOT NULL)
#  index_driver_app_sessions_on_company_id                  (company_id)
#  index_driver_app_sessions_on_driver_id_and_signed_in_at  (driver_id,signed_in_at) WHERE (driver_id IS NOT NULL)
#  index_driver_app_sessions_on_tracking_device_id          (tracking_device_id)
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (driver_id => drivers.id)
#  fk_rails_...  (operator_driver_id => operator_drivers.id)
#  fk_rails_...  (tracking_device_id => tracking_devices.id) ON DELETE => nullify
#
class DriverAppSession < ApplicationRecord
  include TenantScoped

  belongs_to :driver, optional: true
  belongs_to :operator_driver, optional: true
  belongs_to :tracking_device, optional: true

  scope :signed_in, -> { where(signed_out_at: nil) }

  validate :one_driver

  private

  def one_driver
    errors.add(:base, "Needs a driver or an operator driver") unless [ driver_id, operator_driver_id ].compact.size == 1
  end
end
