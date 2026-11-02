# Split Payments: a share of the bonus paid months after the period ends (the first) or after the payment before.
# == Schema Information
#
# Table name: pay_bonus_payments
# Database name: primary
#
#  id           :bigint           not null, primary key
#  months_after :integer          default(1), not null
#  percentage   :integer          not null
#  position     :integer          default(0), not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  pay_bonus_id :bigint           not null
#
# Indexes
#
#  index_pay_bonus_payments_on_pay_bonus_id  (pay_bonus_id)
#
# Foreign Keys
#
#  fk_rails_...  (pay_bonus_id => pay_bonuses.id)
#
class PayBonusPayment < ApplicationRecord
  belongs_to :bonus, class_name: "PayBonus", foreign_key: :pay_bonus_id, inverse_of: :payments

  validates :percentage, numericality: { only_integer: true, in: 1..100 }
  validates :months_after, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end
