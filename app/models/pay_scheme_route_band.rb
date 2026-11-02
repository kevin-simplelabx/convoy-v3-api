# School route retainer: routes up to this many minutes long pay this much a month (the last band, with no limit,
# covers longer routes).
# == Schema Information
#
# Table name: pay_scheme_route_bands
# Database name: primary
#
#  id             :bigint           not null, primary key
#  monthly_amount :decimal(12, 2)   not null
#  position       :integer          default(0), not null
#  up_to_minutes  :integer
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  pay_scheme_id  :bigint           not null
#
# Indexes
#
#  index_pay_scheme_route_bands_on_pay_scheme_id  (pay_scheme_id)
#
# Foreign Keys
#
#  fk_rails_...  (pay_scheme_id => pay_schemes.id)
#
class PaySchemeRouteBand < ApplicationRecord
  belongs_to :scheme, class_name: "PayScheme", foreign_key: :pay_scheme_id, inverse_of: :route_bands

  validates :up_to_minutes, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validates :monthly_amount, numericality: { greater_than_or_equal_to: 0 }
end
