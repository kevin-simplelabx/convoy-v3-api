# == Schema Information
#
# Table name: companies
# Database name: primary
#
#  id                        :bigint           not null, primary key
#  business_units_enabled    :boolean          default(FALSE), not null
#  code                      :string(6)        not null
#  country                   :string           default("SG"), not null
#  country_set_at            :datetime
#  date_format               :string           default("dmy"), not null
#  external_vehicle_cap      :integer          default(10), not null
#  logo                      :string
#  name                      :string           not null
#  observed_holidays         :string           default("off"), not null
#  on_time_minutes           :integer          default(5), not null
#  route_list_import_enabled :boolean          default(TRUE), not null
#  school_run_enabled        :boolean          default(TRUE), not null
#  short_name                :string(12)
#  speed_limit_kmh           :integer          default(80), not null
#  status                    :string           default("active"), not null
#  stop_photo_auto_driver    :boolean          default(FALSE), not null
#  stop_photo_auto_parent    :boolean          default(FALSE), not null
#  theme_color               :string
#  time_format               :string           default("24"), not null
#  timezone                  :string           default("Asia/Singapore"), not null
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  country_set_by_id         :bigint
#
# Indexes
#
#  index_companies_on_code               (code) UNIQUE
#  index_companies_on_country_set_by_id  (country_set_by_id)
#
# Foreign Keys
#
#  fk_rails_...  (country_set_by_id => users.id)
#
FactoryBot.define do
  factory :company do
    sequence(:name) { |n| "Transport Co #{n}" }
    sequence(:code) { |n| "C#{n.to_s.rjust(3, '0')}" }
  end
end
