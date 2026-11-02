# A bonus tier: trips to reach (trip target) or a percentage range (on-time, attendance); paid as a lump sum or
# per trip (rate_increase), with optional points.
# == Schema Information
#
# Table name: pay_bonus_tiers
# Database name: primary
#
#  id           :bigint           not null, primary key
#  amount       :decimal(12, 2)   default(0.0), not null
#  metric_max   :decimal(5, 2)
#  metric_min   :decimal(5, 2)
#  pay_as       :string           default("lump_sum"), not null
#  points       :integer
#  position     :integer          default(0), not null
#  target_trips :integer
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  pay_bonus_id :bigint           not null
#
# Indexes
#
#  index_pay_bonus_tiers_on_pay_bonus_id  (pay_bonus_id)
#
# Foreign Keys
#
#  fk_rails_...  (pay_bonus_id => pay_bonuses.id)
#
class PayBonusTier < ApplicationRecord
  belongs_to :bonus, class_name: "PayBonus", foreign_key: :pay_bonus_id, inverse_of: :tiers

  enum :pay_as, { lump_sum: "lump_sum", rate_increase: "rate_increase" }, prefix: :pay, validate: true

  validates :amount, numericality: { greater_than_or_equal_to: 0 }
  validates :target_trips, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validates :points, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true

  # What the tier pays for trips in the period.
  def pay_for(trips) = pay_rate_increase? ? amount * trips : amount
end
