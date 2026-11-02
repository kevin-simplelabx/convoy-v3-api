# A company's request for a new platform vehicle type (Vehicle Types > Request a New Type). Not tenant scoped:
# Convoy Admin sees every company's requests; companies see their own (VehicleTypeRequestPolicy::Scope).
# == Schema Information
#
# Table name: vehicle_type_requests
# Database name: primary
#
#  id              :bigint           not null, primary key
#  decided_at      :datetime
#  name            :string           not null
#  reason          :text
#  seats           :integer          not null
#  status          :string           default("pending"), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  company_id      :bigint           not null
#  decided_by_id   :bigint
#  requested_by_id :bigint
#  vehicle_type_id :bigint
#
# Indexes
#
#  index_vehicle_type_requests_on_company_id_and_created_at  (company_id,created_at)
#  index_vehicle_type_requests_on_decided_by_id              (decided_by_id)
#  index_vehicle_type_requests_on_requested_by_id            (requested_by_id)
#  index_vehicle_type_requests_on_status_and_created_at      (status,created_at)
#  index_vehicle_type_requests_on_vehicle_type_id            (vehicle_type_id)
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (decided_by_id => users.id)
#  fk_rails_...  (requested_by_id => users.id)
#  fk_rails_...  (vehicle_type_id => vehicle_types.id)
#
class VehicleTypeRequest < ApplicationRecord
  audited

  belongs_to :company
  belongs_to :requested_by, class_name: "User", optional: true
  belongs_to :decided_by, class_name: "User", optional: true
  belongs_to :vehicle_type, optional: true

  enum :status, { pending: "pending", added: "added", declined: "declined" }, validate: true

  STATUS_LABELS = { "pending" => "Waiting for Convoy", "added" => "Added", "declined" => "Declined" }.freeze

  normalizes :name, with: ->(v) { v.to_s.squish }
  normalizes :reason, with: ->(v) { v.to_s.strip.presence }

  validates :name, presence: { message: "Enter the type name" }
  validates :seats, numericality: { only_integer: true, greater_than: 0, message: "Enter the number of seats" }
  validate :not_listed, on: :create

  def status_label = STATUS_LABELS[status]

  # Add Type: the matching platform type (same name and seats) or a new custom one.
  def approve!(user:, tyre_layout: nil)
    transaction do
      type = VehicleType.matching(name, seats) || VehicleType.create!(
        key: VehicleType.free_key(name, seats), name:, seats:, custom: true,
        tyre_layout: tyre_layout.presence || (seats <= 15 ? "1-1" : "1-2"), position: VehicleType.unscoped.maximum(:position).to_i + 1
      )
      update!(status: :added, vehicle_type: type, decided_by: user, decided_at: Time.current)
    end
  end

  def decline!(user:) = update!(status: :declined, decided_by: user, decided_at: Time.current)

  private

  def not_listed
    errors.add(:name, "#{name} #{seats} seats is already listed. Turn it on above") if name.present? && VehicleType.matching(name, seats)
  end
end
