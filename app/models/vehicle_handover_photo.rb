# One side of a bus at a handover: the photo, and the marked-up copy with the shapes drawn on it (400 x 300 photo units).
# == Schema Information
#
# Table name: vehicle_handover_photos
# Database name: primary
#
#  id                  :bigint           not null, primary key
#  marked_photo        :string
#  marks               :jsonb            not null
#  photo               :string           not null
#  side                :string           not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  vehicle_handover_id :bigint           not null
#
# Indexes
#
#  index_vehicle_handover_photos_on_vehicle_handover_id           (vehicle_handover_id)
#  index_vehicle_handover_photos_on_vehicle_handover_id_and_side  (vehicle_handover_id,side) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (vehicle_handover_id => vehicle_handovers.id) ON DELETE => cascade
#
class VehicleHandoverPhoto < ApplicationRecord
  audited associated_with: :handover

  belongs_to :handover, class_name: "VehicleHandover", foreign_key: :vehicle_handover_id, inverse_of: :photos

  mount_uploader :photo, ImageUploader
  mount_uploader :marked_photo, ImageUploader

  validates :side, inclusion: { in: VehicleHandover::SIDES }, uniqueness: { scope: :vehicle_handover_id }
  validates :photo, presence: true
end
