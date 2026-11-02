# Points given to a driver (by hand or from a bonus), usable until expires_on (24 months). `remaining` is what is left
# after deductions took points from it; once expired, what is left is lost.
# == Schema Information
#
# Table name: driver_point_lots
# Database name: primary
#
#  id                  :bigint           not null, primary key
#  awarded_on          :date             not null
#  expires_on          :date             not null
#  points              :integer          not null
#  reason              :string           not null
#  remaining           :integer          not null
#  source              :string           default("manual"), not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  awarded_by_id       :bigint
#  company_id          :bigint           not null
#  driver_id           :bigint           not null
#  driver_pay_month_id :bigint
#  pay_bonus_id        :bigint
#
# Indexes
#
#  index_driver_point_lots_on_awarded_by_id             (awarded_by_id)
#  index_driver_point_lots_on_company_id                (company_id)
#  index_driver_point_lots_on_driver_id_and_expires_on  (driver_id,expires_on)
#  index_driver_point_lots_on_driver_pay_month_id       (driver_pay_month_id)
#  index_driver_point_lots_on_pay_bonus_id              (pay_bonus_id)
#
# Foreign Keys
#
#  fk_rails_...  (awarded_by_id => users.id)
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (driver_id => drivers.id)
#  fk_rails_...  (driver_pay_month_id => driver_pay_months.id)
#  fk_rails_...  (pay_bonus_id => pay_bonuses.id)
#
class DriverPointLot < ApplicationRecord
  include TenantScoped
  audited associated_with: :driver

  LIFETIME = 24.months

  belongs_to :driver
  belongs_to :awarded_by, class_name: "User", optional: true
  belongs_to :pay_bonus, optional: true
  belongs_to :driver_pay_month, optional: true
  has_many :allocations, class_name: "DriverPointAllocation", dependent: :restrict_with_error

  enum :source, { manual: "manual", bonus: "bonus" }, prefix: :from, validate: true

  validates :points, numericality: { only_integer: true, greater_than: 0 }
  validates :reason, presence: true

  scope :live, ->(today = Date.current) { where(expires_on: today..) }
  scope :expired, ->(today = Date.current) { where(expires_on: ...today) }

  def expired?(today = Date.current) = expires_on < today
end
