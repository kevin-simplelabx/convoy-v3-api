# Points taken off a driver (by hand, later: rewards redeemed), drawn from the lots expiring first.
# == Schema Information
#
# Table name: driver_point_deductions
# Database name: primary
#
#  id             :bigint           not null, primary key
#  deducted_on    :date             not null
#  points         :integer          not null
#  reason         :string           not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  company_id     :bigint           not null
#  deducted_by_id :bigint
#  driver_id      :bigint           not null
#
# Indexes
#
#  index_driver_point_deductions_on_company_id      (company_id)
#  index_driver_point_deductions_on_deducted_by_id  (deducted_by_id)
#  index_driver_point_deductions_on_driver_id       (driver_id)
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (deducted_by_id => users.id)
#  fk_rails_...  (driver_id => drivers.id)
#
class DriverPointDeduction < ApplicationRecord
  include TenantScoped
  audited associated_with: :driver

  belongs_to :driver
  belongs_to :deducted_by, class_name: "User", optional: true
  has_many :allocations, class_name: "DriverPointAllocation", dependent: :delete_all

  validates :points, numericality: { only_integer: true, greater_than: 0 }
  validates :reason, presence: true
end
