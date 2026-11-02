# == Schema Information
#
# Table name: rate_card_ranges
# Database name: primary
#
#  id                  :bigint           not null, primary key
#  ends_at             :integer          not null
#  starts_at           :integer          not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  company_id          :bigint           not null
#  rate_card_period_id :bigint           not null
#
# Indexes
#
#  index_rate_card_ranges_on_company_id           (company_id)
#  index_rate_card_ranges_on_rate_card_period_id  (rate_card_period_id)
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (rate_card_period_id => rate_card_periods.id)
#
class RateCardRange < ApplicationRecord
  include TenantScoped
  include MinuteTime

  belongs_to :period, class_name: "RateCardPeriod", foreign_key: :rate_card_period_id, inverse_of: :ranges

  minute_time :starts_at, :ends_at
end
