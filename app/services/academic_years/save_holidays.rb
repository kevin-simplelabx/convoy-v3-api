# Holidays & Special Days › Save Changes (always editable, the calendar lock does not apply): the year's holidays and
# non-operating days, and its special operating days, saved as the whole list. School Bus runs of the school follow.
module AcademicYears
  class SaveHolidays < ApplicationService
    def initialize(year, holidays:, special_days:)
      @year = year
      @holidays = Array(holidays)
      @special = Array(special_days)
    end

    def call
      AcademicYear.transaction do
        @year.holidays.delete_all
        @year.special_days.delete_all
        @holidays.each.with_index(1) { |h, i| holiday(h, i) }
        @special.each.with_index(1) { |d, i| special(d, i) }
      end
      AcademicYears.resync(@year.school)
      @year.reload
    end

    private

    def holiday(h, i)
      from = h[:starts_on].presence or raise Error, "Holiday #{i} needs a start date"
      @year.holidays.create!(name: h[:name].to_s.strip.presence || raise(Error, "Holiday #{i} needs a name"), starts_on: from,
                             ends_on: h[:ends_on].presence || from, public_holiday_id: h[:public_holiday_id].presence)
    rescue ActiveRecord::RecordInvalid => e
      raise Error, "Holiday #{i}: #{e.record.errors.full_messages.to_sentence}"
    end

    def special(d, i)
      @year.special_days.create!(date: d[:date].presence || raise(Error, "Special day #{i} needs a date"), kind: d[:kind], time: d[:time].presence,
                                 description: d[:description])
    rescue ActiveRecord::RecordInvalid => e
      raise Error, "Special day #{i}: #{e.record.errors.full_messages.to_sentence}"
    end
  end
end
