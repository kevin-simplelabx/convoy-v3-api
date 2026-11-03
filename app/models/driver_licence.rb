# One licence of a driver (Account › Driving Credentials): the driving licence (dl), the vocational licence (vl, e.g.
# BDVL) or another (Class 4A, Omnibus…), with its classes, number, dates and card photos. Belongs to the person and
# travels with them between companies; the app and the company both remind before it expires.
# == Schema Information
#
# Table name: driver_licences
# Database name: primary
#
#  id                :bigint           not null, primary key
#  card_back         :string
#  card_front        :string
#  classes           :string
#  expires_on        :date
#  issued_on         :date
#  kind              :string           not null
#  name              :string           not null
#  number            :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  driver_account_id :bigint           not null
#
# Indexes
#
#  index_driver_licences_on_driver_account_id  (driver_account_id)
#
# Foreign Keys
#
#  fk_rails_...  (driver_account_id => driver_accounts.id) ON DELETE => cascade
#
class DriverLicence < ApplicationRecord
  KINDS = { "dl" => "Driving Licence", "vl" => "Vocational Licence", "other" => "Licence" }.freeze
  # Reminder badges: orange from 90 days before expiry, red from 30.
  DUE_SOON_DAYS = 90
  URGENT_DAYS = 30

  audited associated_with: :driver_account

  belongs_to :driver_account, inverse_of: :licences

  mount_uploader :card_front, ImageUploader
  mount_uploader :card_back, ImageUploader

  normalizes :name, :classes, :number, with: ->(v) { v.to_s.squish.presence }

  validates :kind, inclusion: { in: KINDS.keys }
  validates :name, presence: true
  validates :kind, uniqueness: { scope: :driver_account_id, message: "is already on your list" }, if: -> { kind.in?(%w[dl vl]) }

  before_validation { self.name ||= KINDS[kind] }

  def days_left(on = Date.current) = expires_on && (expires_on - on).to_i

  # missing (no expiry date) | expired | urgent (≤ 30 days) | due_soon (≤ 90 days) | valid
  def expiry_status(on = Date.current)
    days = days_left(on)
    if days.nil? then "missing"
    elsif days.negative? then "expired"
    elsif days <= URGENT_DAYS then "urgent"
    elsif days <= DUE_SOON_DAYS then "due_soon"
    else "valid"
    end
  end

  # What a company keeps of it (no card photos): a row of driver_kyc_profiles.licences.
  def to_share = { kind:, name:, classes:, number:, issued_on: issued_on&.iso8601, expires_on: expires_on&.iso8601 }
end
