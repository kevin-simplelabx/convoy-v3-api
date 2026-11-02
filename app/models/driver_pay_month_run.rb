# What a paid run earned in a confirmed month.
# == Schema Information
#
# Table name: driver_pay_month_runs
# Database name: primary
#
#  id                  :bigint           not null, primary key
#  amount              :decimal(12, 2)   not null
#  hours               :decimal(6, 2)
#  occurrence_date     :date             not null
#  trip_label          :string
#  trip_value          :decimal(10, 2)
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  driver_pay_month_id :bigint           not null
#  occurrence_id       :bigint           not null
#
# Indexes
#
#  idx_on_occurrence_id_occurrence_date_c0b0455ad1     (occurrence_id,occurrence_date)
#  index_driver_pay_month_runs_on_driver_pay_month_id  (driver_pay_month_id)
#
# Foreign Keys
#
#  fk_rails_...  (driver_pay_month_id => driver_pay_months.id)
#
class DriverPayMonthRun < ApplicationRecord
  belongs_to :driver_pay_month
end
