# New Academic Year: 12 months from the start month; operating days and structure copied from another year (not its
# dates) or Mon–Fri with 2 semesters. Cannot overlap another year of the school.
module AcademicYears
  class Create < ApplicationService
    def initialize(school:, start_year:, start_month:, copy_from: nil)
      @school = school
      @start_year = start_year.to_i
      @start_month = start_month.to_i
      @copy = copy_from
    end

    def call
      raise Error, "Pick the start year and month" unless @start_year.between?(2000, 2100) && @start_month.between?(1, 12)

      starts = Date.new(@start_year, @start_month, 1)
      ends = starts.next_year - 1
      clash = @school.academic_years.find_by("starts_on <= ? AND ends_on >= ?", ends, starts)
      raise Error, "This overlaps AY #{clash.key}" if clash

      AcademicYear.transaction do
        year = @school.academic_years.create!(
          start_year: @start_year, start_month: @start_month,
          **(@copy ? @copy.slice(:operating_days, :structure, :period_count, :cca_same_as_terms).symbolize_keys : {})
        )
        year.period_count.times { |i| year.terms.create!(position: i + 1) }
        year
      end
    end
  end
end
