# A period of a rate plan: the days (mon..sun, ph) and times it covers, and a rate per vehicle type. On a public
# holiday only "ph" periods match. A range whose end is before its start runs past midnight (it belongs to its start day).
# == Schema Information
#
# Table name: pay_rate_periods
# Database name: primary
#
#  id               :bigint           not null, primary key
#  days             :string           default([]), not null, is an Array
#  name             :string           not null
#  position         :integer          default(0), not null
#  takes_priority   :boolean          default(FALSE), not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  pay_rate_plan_id :bigint           not null
#
# Indexes
#
#  index_pay_rate_periods_on_pay_rate_plan_id  (pay_rate_plan_id)
#
# Foreign Keys
#
#  fk_rails_...  (pay_rate_plan_id => pay_rate_plans.id)
#
class PayRatePeriod < ApplicationRecord
  DAYS = %w[mon tue wed thu fri sat sun ph].freeze

  belongs_to :plan, class_name: "PayRatePlan", foreign_key: :pay_rate_plan_id, inverse_of: :periods
  has_many :ranges, -> { order(:start_time, :id) }, class_name: "PayRatePeriodRange", dependent: :delete_all, inverse_of: :period
  has_many :rates, class_name: "PayRate", dependent: :delete_all, inverse_of: :period

  normalizes :name, with: ->(v) { v.to_s.squish.presence }
  normalizes :days, with: ->(v) { DAYS & Array(v).map(&:to_s) }

  validates :name, presence: true
  validates :days, presence: { message: "must be picked" }
end
