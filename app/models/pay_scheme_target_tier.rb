# Weekly / Monthly Target Incentive tier: reaching target_trips pays a lump sum or an amount per trip of the period.
# Only the highest target reached is paid.
# == Schema Information
#
# Table name: pay_scheme_target_tiers
# Database name: primary
#
#  id            :bigint           not null, primary key
#  amount        :decimal(12, 2)   default(0.0), not null
#  pay_as        :string           default("lump_sum"), not null
#  period        :string           not null
#  position      :integer          default(0), not null
#  target_trips  :integer          not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  pay_scheme_id :bigint           not null
#
# Indexes
#
#  index_pay_scheme_target_tiers_on_pay_scheme_id  (pay_scheme_id)
#
# Foreign Keys
#
#  fk_rails_...  (pay_scheme_id => pay_schemes.id)
#
class PaySchemeTargetTier < ApplicationRecord
  belongs_to :scheme, class_name: "PayScheme", foreign_key: :pay_scheme_id, inverse_of: :target_tiers

  enum :period, { weekly: "weekly", monthly: "monthly" }, validate: true
  enum :pay_as, { lump_sum: "lump_sum", per_trip: "per_trip" }, prefix: :pay, validate: true

  validates :target_trips, numericality: { only_integer: true, greater_than: 0 }
  validates :amount, numericality: { greater_than_or_equal_to: 0 }
end
