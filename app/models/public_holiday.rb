# == Schema Information
#
# Table name: public_holidays
# Database name: primary
#
#  id         :bigint           not null, primary key
#  date       :date             not null
#  name       :string           not null
#  observed   :boolean          default(FALSE), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  company_id :bigint           not null
#
# Indexes
#
#  index_public_holidays_on_company_id           (company_id)
#  index_public_holidays_on_company_id_and_date  (company_id,date) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#
# A public holiday of the company's country; trips with Run on Public Holidays off skip it.
class PublicHoliday < ApplicationRecord
  include TenantScoped
  include SyncsOccurrences
  audited

  # Trips that skip public holidays run or stop on the changed dates.
  after_commit do
    dates = [ date, date_before_last_save ].compact
    resync_occurrences(Trip.kept.recurring.where(skip_public_holidays: true), from: dates.min, to: dates.max,
                       routes: SchoolRoutes.running_ids)
  end

  PRESETS = YAML.load_file(Rails.root.join("config/presets/public_holidays.yml")).freeze

  validates :date, presence: true, uniqueness: { scope: :company_id }
  validates :name, presence: true

  scope :between, ->(from, to) { where(date: from..to) }
  scope :in_year, ->(year) { where(date: Date.new(year)..Date.new(year, 12, 31)) }

  def self.ransackable_attributes(_auth = nil) = %w[date name observed]

  # Gazetted dates for a country and year from config/presets (MOM for Singapore).
  def self.preset(country, year)
    (PRESETS[country.to_s.downcase] || []).select { |h| h["date"].start_with?(year.to_s) }
  end

  # Add the preset dates for a year; dates already on the list are kept as they are. Returns the new holidays.
  def self.import_preset!(country, year)
    preset(country, year).filter_map do |h|
      next if exists?(date: h["date"])

      create!(date: h["date"], name: h["name"], observed: h["observed"])
    end
  end

  def saturday? = date.saturday?
end
