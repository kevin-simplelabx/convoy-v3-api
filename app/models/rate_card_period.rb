# == Schema Information
#
# Table name: rate_card_periods
# Database name: primary
#
#  id           :bigint           not null, primary key
#  days         :string           default([]), not null, is an Array
#  name         :string           not null
#  override     :boolean          default(FALSE), not null
#  position     :integer          default(0), not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  company_id   :bigint           not null
#  rate_card_id :bigint           not null
#
# Indexes
#
#  index_rate_card_periods_on_company_id    (company_id)
#  index_rate_card_periods_on_rate_card_id  (rate_card_id)
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (rate_card_id => rate_cards.id)
#
# A period of a rate card (Off Peak, Peak, Night, Weekend and PH): days, time ranges and rates by vehicle type.
# An override period wins over the others when both cover a time.
class RateCardPeriod < ApplicationRecord
  include TenantScoped
  audited associated_with: :rate_card

  DAYS = %w[sun mon tue wed thu fri sat].freeze

  belongs_to :rate_card, inverse_of: :periods
  has_many :ranges, class_name: "RateCardRange", dependent: :destroy, inverse_of: :period
  has_many :rates, class_name: "RateCardRate", dependent: :destroy, inverse_of: :period

  validates :name, presence: true
  validate { errors.add(:days, "has an unknown day") if (days - DAYS - [ "ph" ]).any? }

  # Does the period cover a date and minute? A range past midnight belongs to the day it starts.
  def covers?(date, minute, holiday:)
    today = DAYS[date.wday]
    yesterday = DAYS[(date.wday + 6) % 7]
    on_today = days.include?(today) || (holiday && days.include?("ph"))
    ranges.any? do |r|
      if r.starts_at < r.ends_at
        on_today && minute >= r.starts_at && minute < r.ends_at + (r.ends_at == 1439 ? 1 : 0)
      else
        (on_today && minute >= r.starts_at) || (days.include?(yesterday) && minute < r.ends_at)
      end
    end
  end
end
