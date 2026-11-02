# A breakdown row of a confirmed month (per part of the month when the scheme changed).
# == Schema Information
#
# Table name: driver_pay_month_lines
# Database name: primary
#
#  id                  :bigint           not null, primary key
#  amount              :decimal(12, 2)
#  label               :string           not null
#  part_from           :date
#  part_to             :date
#  position            :integer          default(0), not null
#  scheme_name         :string
#  text                :string
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  driver_pay_month_id :bigint           not null
#
# Indexes
#
#  index_driver_pay_month_lines_on_driver_pay_month_id  (driver_pay_month_id)
#
# Foreign Keys
#
#  fk_rails_...  (driver_pay_month_id => driver_pay_months.id)
#
class DriverPayMonthLine < ApplicationRecord
  belongs_to :driver_pay_month
end
