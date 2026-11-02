# A pay scheme whose drivers can join a bonus (none = every scheme).
# == Schema Information
#
# Table name: pay_bonus_schemes
# Database name: primary
#
#  id            :bigint           not null, primary key
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  pay_bonus_id  :bigint           not null
#  pay_scheme_id :bigint           not null
#
# Indexes
#
#  index_pay_bonus_schemes_on_pay_bonus_id_and_pay_scheme_id  (pay_bonus_id,pay_scheme_id) UNIQUE
#  index_pay_bonus_schemes_on_pay_scheme_id                   (pay_scheme_id)
#
# Foreign Keys
#
#  fk_rails_...  (pay_bonus_id => pay_bonuses.id)
#  fk_rails_...  (pay_scheme_id => pay_schemes.id)
#
class PayBonusScheme < ApplicationRecord
  belongs_to :pay_bonus
  belongs_to :pay_scheme
end
