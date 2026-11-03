# A device that reports where a bus is: the Convoy Driver app on the driver's phone, or a GPS tracker fitted to the bus.
# Set up from seed for now (no screen in Convoy OS); pings go through Telematics::Ping.
# == Schema Information
#
# Table name: tracking_devices
# Database name: primary
#
#  id                      :bigint           not null, primary key
#  identifier              :string
#  kind                    :string           not null
#  name                    :string           not null
#  report_interval_seconds :integer          default(10), not null
#  sharing_enabled         :boolean          default(TRUE), not null
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  company_id              :bigint           not null
#  vehicle_id              :bigint
#
# Indexes
#
#  index_tracking_devices_on_company_id                 (company_id)
#  index_tracking_devices_on_company_id_and_identifier  (company_id,identifier) UNIQUE WHERE (identifier IS NOT NULL)
#  index_tracking_devices_on_vehicle_id                 (vehicle_id)
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (vehicle_id => vehicles.id)
#
class TrackingDevice < ApplicationRecord
  include TenantScoped
  audited

  KINDS = %w[driver_app gps_tracker].freeze

  belongs_to :vehicle, optional: true
  has_many :live_positions, class_name: "VehicleLivePosition", dependent: :nullify

  enum :kind, KINDS.index_with(&:itself), validate: true

  normalizes :identifier, with: ->(v) { v.to_s.strip.presence }

  validates :name, presence: true
  validates :identifier, uniqueness: { scope: :company_id }, allow_nil: true
  validates :report_interval_seconds, numericality: { only_integer: true, in: 1..3600 }
end
