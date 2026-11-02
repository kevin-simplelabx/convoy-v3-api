# Daily Volume Incentive tier: trips number from_trip..to_trip of a day (to_trip nil = no limit) get a boost —
# flat (S$ a trip), percentage (of the rate) or fixed_rate (paid at this rate if higher).
# == Schema Information
#
# Table name: pay_scheme_volume_tiers
# Database name: primary
#
#  id            :bigint           not null, primary key
#  boost_type    :string           default("flat"), not null
#  boost_value   :decimal(12, 2)   default(0.0), not null
#  from_trip     :integer          not null
#  position      :integer          default(0), not null
#  to_trip       :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  pay_scheme_id :bigint           not null
#
# Indexes
#
#  index_pay_scheme_volume_tiers_on_pay_scheme_id  (pay_scheme_id)
#
# Foreign Keys
#
#  fk_rails_...  (pay_scheme_id => pay_schemes.id)
#
class PaySchemeVolumeTier < ApplicationRecord
  belongs_to :scheme, class_name: "PayScheme", foreign_key: :pay_scheme_id, inverse_of: :volume_tiers

  enum :boost_type, { flat: "flat", percentage: "percentage", fixed_rate: "fixed_rate" }, prefix: :boost, validate: true

  validates :from_trip, numericality: { only_integer: true, greater_than: 0 }
  validates :to_trip, numericality: { only_integer: true, greater_than_or_equal_to: :from_trip }, allow_nil: true
  validates :boost_value, numericality: { greater_than_or_equal_to: 0 }
end
