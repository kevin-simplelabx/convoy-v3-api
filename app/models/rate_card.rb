# == Schema Information
#
# Table name: rate_cards
# Database name: primary
#
#  id                 :bigint           not null, primary key
#  archived_at        :datetime
#  default_card       :boolean          default(FALSE), not null
#  description        :text
#  disposal_free_km   :decimal(8, 1)    default(0.0), not null
#  disposal_mode      :string           default("hourly"), not null
#  distance_pricing   :boolean          default(FALSE), not null
#  lock_version       :integer          default(0), not null
#  meet_and_greet     :boolean          default(FALSE), not null
#  meet_and_greet_fee :decimal(10, 2)   default(0.0), not null
#  name               :string           not null
#  stop_fees          :boolean          default(FALSE), not null
#  wait_block_minutes :integer          default(15), not null
#  wait_fee           :decimal(10, 2)   default(15.0), not null
#  wait_free_minutes  :integer          default(10), not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  company_id         :bigint           not null
#
# Indexes
#
#  index_rate_cards_on_company_and_name  (company_id, lower((name)::text)) UNIQUE
#  index_rate_cards_on_company_id        (company_id)
#  index_rate_cards_one_default          (company_id) UNIQUE WHERE (default_card AND (archived_at IS NULL))
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#
# A named rate card: periods with a trip and hourly rate per vehicle type, plus waiting, distance, stop, disposal and
# meet and greet rules. A client uses its assigned card, else the company's default. Edited on Trips > Rate Cards (RateCards::Save).
class RateCard < ApplicationRecord
  include TenantScoped
  audited

  has_many :card_vehicle_types, -> { order(:position) }, class_name: "RateCardVehicleType", dependent: :delete_all, inverse_of: :rate_card
  has_many :vehicle_types, through: :card_vehicle_types
  has_many :periods, -> { order(:position) }, class_name: "RateCardPeriod", dependent: :destroy, inverse_of: :rate_card
  has_many :distance_bands, -> { order(:position) }, class_name: "RateCardDistanceBand", dependent: :destroy, inverse_of: :rate_card
  has_many :amounts, class_name: "RateCardAmount", dependent: :destroy, inverse_of: :rate_card
  has_many :clients, dependent: :restrict_with_error

  enum :disposal_mode, { hourly: "hourly", hourly_distance: "hourly_distance" }, prefix: :disposal, validate: true

  validates :name, presence: true, length: { maximum: 80 }
  validates :wait_free_minutes, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :wait_block_minutes, numericality: { only_integer: true, greater_than: 0 }
  validates :wait_fee, :meet_and_greet_fee, :disposal_free_km, numericality: { greater_than_or_equal_to: 0 }

  scope :active, -> { where(archived_at: nil) }
  scope :archived, -> { where.not(archived_at: nil) }

  def archived? = archived_at.present?

  # Clients priced by this card: assigned to it, or (the default card) assigned to none.
  def clients_using
    default_card? ? Client.kept.where(rate_card_id: [ id, nil ]) : Client.kept.where(rate_card_id: id)
  end

  def self.for_client(client) = client&.rate_card&.then { |c| c.archived_at ? nil : c } || active.find_by(default_card: true) || active.first

  # The extra amount of a kind for a vehicle type (stop_fee, disposal_km, or a distance band's).
  def amount_for(kind, vehicle_type, band: nil)
    amounts.find { |a| a.kind == kind && a.vehicle_type_id == vehicle_type.id && a.rate_card_distance_band_id == band&.id }&.amount.to_d
  end
end
