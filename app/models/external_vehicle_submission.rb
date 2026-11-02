# A hired driver's answer from the Share Form: the bus, the driver and the company they drive for. Waits as pending
# until Review and Add (added, vehicle set) or Dismiss.
# == Schema Information
#
# Table name: external_vehicle_submissions
# Database name: primary
#
#  id            :bigint           not null, primary key
#  company_name  :string           not null
#  company_phone :string
#  decided_at    :datetime
#  driver_name   :string           not null
#  driver_phone  :string           not null
#  paynow        :string
#  plate         :string           not null
#  seats         :integer
#  status        :string           default("pending"), not null
#  submitted_ip  :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  company_id    :bigint           not null
#  decided_by_id :bigint
#  share_link_id :bigint           not null
#  vehicle_id    :bigint
#
# Indexes
#
#  idx_on_company_id_status_created_at_f335c61b86       (company_id,status,created_at)
#  index_external_vehicle_submissions_on_decided_by_id  (decided_by_id)
#  index_external_vehicle_submissions_on_share_link_id  (share_link_id)
#  index_external_vehicle_submissions_on_vehicle_id     (vehicle_id)
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (decided_by_id => users.id)
#  fk_rails_...  (share_link_id => external_vehicle_share_links.id)
#  fk_rails_...  (vehicle_id => vehicles.id)
#
class ExternalVehicleSubmission < ApplicationRecord
  include TenantScoped
  audited

  belongs_to :share_link, class_name: "ExternalVehicleShareLink", inverse_of: :submissions
  belongs_to :vehicle, optional: true
  belongs_to :decided_by, class_name: "User", optional: true

  enum :status, { pending: "pending", added: "added", dismissed: "dismissed" }, validate: true

  normalizes :plate, with: ->(v) { v.to_s.gsub(/\s+/, "").upcase }
  normalizes :driver_name, :company_name, :company_phone, :paynow, with: ->(v) { v.to_s.squish.presence }
  normalizes :driver_phone, with: ->(v) { v.to_s.strip }

  validates :plate, presence: { message: "Enter the licence plate" }
  validates :driver_name, presence: { message: "Enter your name" }
  validates :company_name, presence: { message: "Enter the company you drive for" }
  validates :seats, numericality: { only_integer: true, greater_than: 0, allow_nil: true }
  validate { errors.add(:driver_phone, "Enter your mobile number") if driver_phone.to_s.gsub(/\D/, "").length < 8 }

  def decide!(status, user:, vehicle: nil) = update!(status:, vehicle:, decided_by: user, decided_at: Time.current)
end
