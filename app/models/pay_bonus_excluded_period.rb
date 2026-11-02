# Attendance bonus: days that don't count (school holidays, a shutdown).
# == Schema Information
#
# Table name: pay_bonus_excluded_periods
# Database name: primary
#
#  id           :bigint           not null, primary key
#  ends_on      :date             not null
#  name         :string
#  starts_on    :date             not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  pay_bonus_id :bigint           not null
#
# Indexes
#
#  index_pay_bonus_excluded_periods_on_pay_bonus_id  (pay_bonus_id)
#
# Foreign Keys
#
#  fk_rails_...  (pay_bonus_id => pay_bonuses.id)
#
class PayBonusExcludedPeriod < ApplicationRecord
  belongs_to :bonus, class_name: "PayBonus", foreign_key: :pay_bonus_id, inverse_of: :excluded_periods

  validates :starts_on, :ends_on, presence: true
  validate { errors.add(:ends_on, "is before the start date") if starts_on && ends_on && ends_on < starts_on }
end
