# A school's academic year for the School Bus service: 12 months from its start month (key "2026" when it starts in
# January, else "2026/27"), operating days, 2 semesters or 3 / 4 terms (each with its CCA / ASA period, the term's dates
# unless set apart), holidays and special operating days. A school day is an operating day inside a term and not in a
# holiday; School Bus runs, fares and route costs count them.
# == Schema Information
#
# Table name: academic_years
# Database name: primary
#
#  id                :bigint           not null, primary key
#  cca_same_as_terms :boolean          default(TRUE), not null
#  ends_on           :date             not null
#  key               :string           not null
#  operating_days    :integer          default([1, 2, 3, 4, 5]), not null, is an Array
#  period_count      :integer          default(2), not null
#  start_month       :integer          not null
#  start_year        :integer          not null
#  starts_on         :date             not null
#  structure         :string           default("semester"), not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  company_id        :bigint           not null
#  school_id         :bigint           not null
#
# Indexes
#
#  index_academic_years_on_school_id_and_key                    (school_id,key) UNIQUE
#  index_academic_years_on_school_id_and_starts_on_and_ends_on  (school_id,starts_on,ends_on)
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (school_id => schools.id)
#
class AcademicYear < ApplicationRecord
  include TenantScoped
  audited associated_with: :school

  STRUCTURES = { "semester" => [ 2 ], "term" => [ 3, 4 ] }.freeze

  belongs_to :school
  has_many :terms, -> { order(:position) }, class_name: "AcademicTerm", dependent: :delete_all, inverse_of: :academic_year
  has_many :holidays, -> { order(:starts_on, :id) }, class_name: "SchoolHoliday", dependent: :delete_all, inverse_of: :academic_year
  has_many :special_days, -> { order(:date, :id) }, class_name: "SchoolSpecialDay", dependent: :delete_all, inverse_of: :academic_year
  has_many :setup_locks, dependent: :delete_all
  has_many :bus_sessions, -> { order(:position) }, dependent: :destroy, inverse_of: :academic_year
  has_one :fare_table, dependent: :destroy
  has_one :registration, class_name: "SchoolRegistration", dependent: :destroy

  validates :key, presence: true, uniqueness: { scope: :school_id }
  validates :start_month, inclusion: { in: 1..12 }
  validates :structure, inclusion: { in: STRUCTURES.keys }
  validate :period_count_fits

  before_validation :set_span, if: -> { start_year && start_month }

  scope :covering, ->(date) { where(starts_on: ..date, ends_on: date..) }

  def self.key_for(year, month) = month == 1 ? year.to_s : "#{year}/#{(year + 1).to_s[-2..]}"

  def period_label = structure == "semester" ? "Semester" : "Term"
  def started?(today = Date.current) = today >= starts_on
  def lock_of(section) = setup_locks.find { it.section == section.to_s }

  # Is the date a school day (operating day, inside a term, not a holiday)?
  def school_day?(date)
    operating_days.include?(date.cwday) && terms.any? { |t| t.covers?(date) } && holidays.none? { |h| h.covers?(date) }
  end

  # Operating days between two dates (inclusive) that are not holidays — the count shown under each term.
  def school_days_between(from, to)
    return 0 unless from && to

    (from..to).count { |d| operating_days.include?(d.cwday) && holidays.none? { |h| h.covers?(d) } }
  end

  def school_days = terms.sum { |t| school_days_between(t.starts_on, t.ends_on) }

  def in_cca_period?(date)
    terms.any? { |t| cca_same_as_terms ? t.covers?(date) : t.cca_covers?(date) }
  end

  private

  def set_span
    self.key = self.class.key_for(start_year, start_month)
    self.starts_on = Date.new(start_year, start_month, 1)
    self.ends_on = starts_on.next_year - 1
  end

  def period_count_fits
    errors.add(:period_count, "must be #{STRUCTURES[structure].to_sentence(last_word_connector: ' or ')}") unless STRUCTURES[structure]&.include?(period_count)
  end
end
