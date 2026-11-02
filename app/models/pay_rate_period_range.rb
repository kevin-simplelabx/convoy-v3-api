# A time range of a rate period, in minutes after midnight. 23:59 as the end means the end of the day.
# == Schema Information
#
# Table name: pay_rate_period_ranges
# Database name: primary
#
#  id                 :bigint           not null, primary key
#  end_time           :integer          not null
#  start_time         :integer          not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  pay_rate_period_id :bigint           not null
#
# Indexes
#
#  index_pay_rate_period_ranges_on_pay_rate_period_id  (pay_rate_period_id)
#
# Foreign Keys
#
#  fk_rails_...  (pay_rate_period_id => pay_rate_periods.id)
#
class PayRatePeriodRange < ApplicationRecord
  include MinuteTime

  belongs_to :period, class_name: "PayRatePeriod", foreign_key: :pay_rate_period_id, inverse_of: :ranges

  minute_time :start_time, :end_time

  validates :start_time, :end_time, presence: true

  def overnight? = end_time <= start_time
  # 23:59 counts as 24:00.
  def end_minute = end_time == 1439 ? 1440 : end_time
end
