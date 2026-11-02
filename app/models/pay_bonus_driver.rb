# A driver picked for a bonus (role eligible: only picked drivers can join) or signed up to it (role signed_up: in
# the driver app, or ticked by hand — signed_up_by).
# == Schema Information
#
# Table name: pay_bonus_drivers
# Database name: primary
#
#  id              :bigint           not null, primary key
#  role            :string           not null
#  signed_up_at    :datetime
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  driver_id       :bigint           not null
#  pay_bonus_id    :bigint           not null
#  signed_up_by_id :bigint
#
# Indexes
#
#  index_pay_bonus_drivers_on_driver_id                            (driver_id)
#  index_pay_bonus_drivers_on_pay_bonus_id_and_role_and_driver_id  (pay_bonus_id,role,driver_id) UNIQUE
#  index_pay_bonus_drivers_on_signed_up_by_id                      (signed_up_by_id)
#
# Foreign Keys
#
#  fk_rails_...  (driver_id => drivers.id)
#  fk_rails_...  (pay_bonus_id => pay_bonuses.id)
#  fk_rails_...  (signed_up_by_id => users.id)
#
class PayBonusDriver < ApplicationRecord
  belongs_to :pay_bonus
  belongs_to :driver
  belongs_to :signed_up_by, class_name: "User", optional: true

  validates :role, inclusion: { in: %w[eligible signed_up] }
end
