# == Schema Information
#
# Table name: vehicle_types
# Database name: primary
#
#  id          :bigint           not null, primary key
#  custom      :boolean          default(FALSE), not null
#  key         :string           not null
#  name        :string           not null
#  position    :integer          default(0), not null
#  seats       :integer          not null
#  tyre_layout :string           default("1-1"), not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_vehicle_types_on_key  (key) UNIQUE
#
# Platform vehicle type (Car 4 seats, Minibus 13, Coach 45...). Only Convoy adds or removes them; built-in types (seeded)
# stay, custom ones (added by hand or from a company's request) can be removed while no trip uses them.
class VehicleType < ApplicationRecord
  TYRE_LAYOUTS = {
    "1-1" => "2 axles, 1 tyre each side (4 tyres)",
    "1-2" => "2 axles, front 1 and rear 2 each side (6 tyres)",
    "1-1-2" => "3 axles, front and middle 1, rear 2 each side (8 tyres)",
    "1-2-2" => "3 axles, front 1, two rear axles 2 each side (10 tyres)"
  }.freeze

  has_many :disabled_vehicle_types, dependent: :destroy
  has_many :trip_vehicle_requirements, dependent: :restrict_with_error
  has_many :requests, class_name: "VehicleTypeRequest", dependent: :nullify

  validates :key, presence: true, uniqueness: true, format: { with: /\A[a-z0-9_]+\z/ }
  validates :name, presence: true
  validates :seats, numericality: { only_integer: true, greater_than: 0 }
  validates :tyre_layout, inclusion: { in: TYRE_LAYOUTS.keys }

  default_scope { order(:position, :seats) }

  # Types the current company has not turned off.
  scope :enabled_for, ->(company) { where.not(id: DisabledVehicleType.where(company:).select(:vehicle_type_id)) }

  def label = "#{name} | #{seats} seats"

  def tyre_text = TYRE_LAYOUTS[tyre_layout]

  # Same name (any case) and seats.
  def self.matching(name, seats) = unscoped.where("LOWER(name) = ?", name.to_s.squish.downcase).find_by(seats:)

  # "Luxury Coach", 27 → "luxury_coach_27" (with a number added when taken).
  def self.free_key(name, seats)
    base = "#{name.to_s.parameterize(separator: '_')}_#{seats}"
    key = base
    n = 1
    key = "#{base}_#{n += 1}" while unscoped.exists?(key:)
    key
  end

  def enabled_for?(company)
    !disabled_vehicle_types.exists?(company:)
  end
end
