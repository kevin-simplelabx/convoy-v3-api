# The last report of a bus (Live Map): where it was, how fast, and the device's battery and signal. One row per vehicle,
# overwritten by Telematics::Ping; the run it was on at the time is kept by (occurrence_id, occurrence_date).
# == Schema Information
#
# Table name: vehicle_live_positions
# Database name: primary
#
#  id                 :bigint           not null, primary key
#  battery_pct        :integer
#  gps_signal         :string
#  gsm_bars           :integer
#  heading            :integer
#  lat                :float            not null
#  lng                :float            not null
#  occurrence_date    :date
#  recorded_at        :timestamptz      not null
#  speed_kmh          :float(24)
#  company_id         :bigint           not null
#  occurrence_id      :bigint
#  tracking_device_id :bigint
#  vehicle_id         :bigint           not null
#
# Indexes
#
#  index_vehicle_live_positions_on_company_id          (company_id)
#  index_vehicle_live_positions_on_tracking_device_id  (tracking_device_id)
#  index_vehicle_live_positions_on_vehicle_id          (vehicle_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (tracking_device_id => tracking_devices.id) ON DELETE => nullify
#  fk_rails_...  (vehicle_id => vehicles.id)
#
class VehicleLivePosition < ApplicationRecord
  include TenantScoped

  GPS_SIGNALS = %w[good fair poor none].freeze

  belongs_to :vehicle
  belongs_to :tracking_device, optional: true

  validates :gps_signal, inclusion: { in: GPS_SIGNALS }, allow_nil: true
  validates :gsm_bars, numericality: { only_integer: true, in: 0..4 }, allow_nil: true
  validates :battery_pct, numericality: { only_integer: true, in: 0..100 }, allow_nil: true
end
