# The Bus Fares of a school's academic year: who pays (parents, the school per rider, or the school per bus), how fares
# are set and spread over the billing periods (terms or chosen months), and the options (1-way, bus sizes, Small Bus,
# Express, CCA / ASA, location surcharges). Saved whole from the wizard and locked; period_snapshot keeps each period's
# [school days, CCA days] from the moment it was locked, so later holiday edits do not change bills.
# == Schema Information
#
# Table name: fare_tables
# Database name: primary
#
#  id                :bigint           not null, primary key
#  basis             :string           default("distance"), not null
#  bill_to_contact   :string
#  bill_to_email     :string
#  bill_to_name      :string
#  bus_count         :string           default("plan"), not null
#  by_size           :boolean          default(FALSE), not null
#  cca_am_amount     :decimal(12, 2)
#  cca_am_on         :boolean          default(FALSE), not null
#  cca_am_type       :string           default("pct"), not null
#  cca_fixed         :decimal(12, 2)
#  cca_non_amount    :decimal(12, 2)
#  cca_non_on        :boolean          default(FALSE), not null
#  cca_non_type      :string           default("pct"), not null
#  cca_on            :boolean          default(FALSE), not null
#  cca_per           :string           default("trip"), not null
#  cca_pm_amount     :decimal(12, 2)
#  cca_pm_on         :boolean          default(FALSE), not null
#  cca_pm_type       :string           default("pct"), not null
#  cca_price         :string           default("fixed"), not null
#  cca_split         :string           default("equal"), not null
#  cca_with_services :boolean          default(FALSE), not null
#  cycle             :string           default("period"), not null
#  distribution      :string           default("equal"), not null
#  express_on        :boolean          default(FALSE), not null
#  express_type      :string           default("pct"), not null
#  express_value     :decimal(12, 2)
#  months            :integer          default([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]), not null, is an Array
#  one_way_type      :string           default("pct"), not null
#  one_way_value     :decimal(12, 2)
#  payer             :string           default("parents"), not null
#  period_snapshot   :jsonb
#  small_on          :boolean          default(FALSE), not null
#  small_seats       :integer          default(15), not null
#  small_type        :string           default("pct"), not null
#  small_value       :decimal(12, 2)
#  trip              :string           default("both"), not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  academic_year_id  :bigint           not null
#  company_id        :bigint           not null
#
# Indexes
#
#  index_fare_tables_on_academic_year_id  (academic_year_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (academic_year_id => academic_years.id) ON DELETE => cascade
#  fk_rails_...  (company_id => companies.id)
#
class FareTable < ApplicationRecord
  include TenantScoped
  audited associated_with: :academic_year

  PAYERS = %w[parents school bus].freeze
  BASES = %w[distance zone].freeze
  TRIPS = %w[both one ampm].freeze
  CYCLES = %w[period month].freeze
  DISTRIBUTIONS = %w[equal prorated bill billpro custom].freeze
  ONE_WAY = %w[pct flat custom].freeze
  SERVICE_TYPES = %w[pct flat custom].freeze
  RIDER_RULES = %w[pct flat fixed].freeze

  belongs_to :academic_year
  has_many :tiers, -> { order(:position) }, class_name: "FareTier", dependent: :delete_all, inverse_of: :fare_table
  has_many :size_columns, -> { order(:position) }, class_name: "FareSizeColumn", dependent: :delete_all, inverse_of: :fare_table
  has_many :surcharges, -> { order(:position) }, class_name: "FareSurcharge", dependent: :delete_all, inverse_of: :fare_table
  has_many :bus_rates, -> { order(:bus_type) }, class_name: "FareBusRate", dependent: :delete_all, inverse_of: :fare_table

  validates :payer, inclusion: { in: PAYERS }
  validates :basis, inclusion: { in: BASES }
  validates :trip, inclusion: { in: TRIPS }
  validates :cycle, inclusion: { in: CYCLES }
  validates :distribution, inclusion: { in: DISTRIBUTIONS }
  validates :one_way_type, inclusion: { in: ONE_WAY }
  validates :small_type, :express_type, inclusion: { in: SERVICE_TYPES }
  validates :cca_per, inclusion: { in: %w[trip period] }
  validates :cca_price, inclusion: { in: %w[fixed tier] }
  validates :cca_split, inclusion: { in: %w[equal days] }
  validates :bus_count, inclusion: { in: %w[plan booked] }
  validates :cca_non_type, :cca_am_type, :cca_pm_type, inclusion: { in: RIDER_RULES }

  def per_bus? = payer == "bus"
  def zones? = basis == "zone"
  def per_bill? = %w[bill billpro custom].include?(distribution)
  def locked? = academic_year.lock_of(:fares).present?
end
