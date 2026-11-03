# A holiday or non-operating period of a school's academic year (Holidays & Special Days): no School Bus runs.
# public_holiday_id is set when it was imported from the public holidays.
# == Schema Information
#
# Table name: school_holidays
# Database name: primary
#
#  id                :bigint           not null, primary key
#  ends_on           :date             not null
#  name              :string           not null
#  starts_on         :date             not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  academic_year_id  :bigint           not null
#  company_id        :bigint           not null
#  public_holiday_id :bigint
#
# Indexes
#
#  index_school_holidays_on_academic_year_id_and_starts_on  (academic_year_id,starts_on)
#
# Foreign Keys
#
#  fk_rails_...  (academic_year_id => academic_years.id) ON DELETE => cascade
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (public_holiday_id => public_holidays.id) ON DELETE => nullify
#
class SchoolHoliday < ApplicationRecord
  include TenantScoped
  audited associated_with: :academic_year

  belongs_to :academic_year, inverse_of: :holidays
  belongs_to :public_holiday, optional: true

  validates :name, :starts_on, :ends_on, presence: true
  validate { errors.add(:ends_on, "must be on or after the start") if starts_on && ends_on && ends_on < starts_on }

  def covers?(date) = date.between?(starts_on, ends_on)
end
