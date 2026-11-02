# HR > Earnings: a driver's month confirmed at a total (frozen breakdown and paid runs). Reopen deletes it.
# == Schema Information
#
# Table name: driver_pay_months
# Database name: primary
#
#  id              :bigint           not null, primary key
#  confirmed_at    :datetime         not null
#  month           :date             not null
#  runs_count      :integer          default(0), not null
#  total           :decimal(12, 2)   not null
#  trips           :decimal(10, 2)   default(0.0), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  company_id      :bigint           not null
#  confirmed_by_id :bigint
#  driver_id       :bigint           not null
#
# Indexes
#
#  index_driver_pay_months_on_company_id_and_month  (company_id,month)
#  index_driver_pay_months_on_confirmed_by_id       (confirmed_by_id)
#  index_driver_pay_months_on_driver_id_and_month   (driver_id,month) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (confirmed_by_id => users.id)
#  fk_rails_...  (driver_id => drivers.id)
#
class DriverPayMonth < ApplicationRecord
  include TenantScoped
  audited associated_with: :driver

  belongs_to :driver
  belongs_to :confirmed_by, class_name: "User", optional: true
  has_many :lines, -> { order(:position) }, class_name: "DriverPayMonthLine", dependent: :delete_all
  has_many :runs, class_name: "DriverPayMonthRun", dependent: :delete_all

  validates :month, presence: true, uniqueness: { scope: :driver_id }

  def self.confirmed_for?(driver_id, date) = driver_id && exists?(driver_id:, month: date.beginning_of_month)
end
